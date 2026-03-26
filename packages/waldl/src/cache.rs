#![allow(dead_code)]

use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

use anyhow::{Context, anyhow};
use directories::ProjectDirs;
use futures::StreamExt;
use tokio::io::AsyncWriteExt;

use crate::api::{SearchResponse, Wallpaper};

/// Cache manager for thumbnails, API responses, and wallpaper downloads.
#[derive(Debug, Clone)]
pub struct Cache {
    cache_dir: PathBuf,
    thumbnail_dir: PathBuf,
    api_cache_dir: PathBuf,
}

impl Cache {
    /// Creates a new Cache instance, creating directories as needed.
    pub fn new() -> anyhow::Result<Cache> {
        let cache_dir = Self::determine_cache_dir()?;
        let thumbnail_dir = cache_dir.join("thumbnails");
        let api_cache_dir = cache_dir.join("api_cache");

        // Create all cache directories
        std::fs::create_dir_all(&thumbnail_dir)
            .context("failed to create thumbnail cache directory")?;
        std::fs::create_dir_all(&api_cache_dir).context("failed to create API cache directory")?;

        Ok(Cache {
            cache_dir,
            thumbnail_dir,
            api_cache_dir,
        })
    }

    /// Returns the base cache directory.
    pub fn cache_dir(&self) -> &Path {
        &self.cache_dir
    }

    /// Returns the path to the persistent debug log file.
    pub fn debug_log_path(&self) -> PathBuf {
        self.cache_dir.join("debug.log")
    }

    /// Appends one debug entry to the persistent log file.
    pub fn append_debug_log(&self, message: &str) -> anyhow::Result<()> {
        let path = self.debug_log_path();
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).context("failed to create debug log directory")?;
        }
        let ts = chrono::Local::now().to_rfc3339();
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path)
            .with_context(|| format!("failed to open debug log at {}", path.display()))?;
        use std::io::Write;
        writeln!(file, "[{ts}] {message}")
            .with_context(|| format!("failed to append debug log at {}", path.display()))?;
        Ok(())
    }

    /// Determines the cache directory using XDG convention.
    fn determine_cache_dir() -> anyhow::Result<PathBuf> {
        if let Some(proj_dirs) = ProjectDirs::from("cc", "", "waldl") {
            return Ok(proj_dirs.cache_dir().to_path_buf());
        }

        // Fallback: XDG_CACHE_HOME or ~/.cache/waldl
        let base = std::env::var("XDG_CACHE_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|_| {
                dirs::home_dir()
                    .map(|h| h.join(".cache"))
                    .unwrap_or_else(|| PathBuf::from(".cache"))
            });

        Ok(base.join("waldl"))
    }

    /// Returns the path where a thumbnail should be cached.
    pub fn thumbnail_path(&self, wallpaper_id: &str, url: &str) -> PathBuf {
        let ext = extract_extension(url).unwrap_or_else(|| "jpg".to_string());
        self.thumbnail_dir.join(format!("{}.{}", wallpaper_id, ext))
    }

    /// Checks if a thumbnail is already cached.
    pub fn has_thumbnail(&self, wallpaper_id: &str, url: &str) -> bool {
        self.thumbnail_path(wallpaper_id, url).exists()
    }

    /// Downloads all missing thumbnails in parallel (up to 8 concurrent).
    pub async fn download_thumbnails(
        &self,
        client: &reqwest::Client,
        wallpapers: &[Wallpaper],
    ) -> anyhow::Result<()> {
        let pending: Vec<_> = wallpapers
            .iter()
            .filter(|w| !self.has_thumbnail(&w.id, &w.thumbs.original))
            .collect();

        if pending.is_empty() {
            return Ok(());
        }

        let client = client.clone();
        let cache = self.clone();

        futures::stream::iter(pending)
            .map(|w| {
                let client = &client;
                let cache = &cache;
                async move {
                    download_thumbnail(client, cache, w).await;
                }
            })
            .buffer_unordered(8)
            .collect::<()>()
            .await;

        Ok(())
    }

    /// Downloads a full wallpaper image to the destination directory.
    /// Skips download if the file already exists.
    pub async fn download_wallpaper(
        &self,
        client: &reqwest::Client,
        wallpaper: &Wallpaper,
        dest_dir: &Path,
    ) -> anyhow::Result<PathBuf> {
        let ext = extract_extension(&wallpaper.path).unwrap_or_else(|| "jpg".to_string());
        let filename = format!("wallhaven-{}.{}", wallpaper.id, ext);
        let dest_path = dest_dir.join(&filename);

        // Skip if already downloaded
        if dest_path.exists() {
            return Ok(dest_path);
        }

        // Ensure destination directory exists
        if !dest_dir.exists() {
            std::fs::create_dir_all(dest_dir)
                .context("failed to create wallpaper destination directory")?;
        }

        // Download to temp file first, then rename
        let tmp_path = dest_path.with_extension(format!("{}.tmp", ext));

        let response = client
            .get(&wallpaper.path)
            .send()
            .await
            .with_context(|| format!("failed to download wallpaper {}", wallpaper.id))?;

        if !response.status().is_success() {
            return Err(anyhow!(
                "HTTP error {} downloading wallpaper {}",
                response.status(),
                wallpaper.id
            ));
        }

        let mut file = tokio::fs::File::create(&tmp_path)
            .await
            .context("failed to create wallpaper temp file")?;
        let mut stream = response.bytes_stream();
        while let Some(chunk) = stream.next().await {
            let chunk = chunk.context("error reading wallpaper response")?;
            tokio::io::AsyncWriteExt::write_all(&mut file, &chunk)
                .await
                .context("failed to write wallpaper chunk")?;
        }

        // Ensure temp file is flushed before rename
        file.flush()
            .await
            .context("failed to flush wallpaper temp file")?;

        std::fs::rename(&tmp_path, &dest_path).context("failed to rename wallpaper temp file")?;

        Ok(dest_path)
    }

    /// Retrieves a cached search response if it exists and is fresh (less than 1 hour old).
    pub async fn get_cached_search(
        &self,
        cache_key: &str,
        page: u32,
    ) -> anyhow::Result<Option<SearchResponse>> {
        let cache_file = self.cache_file_path(cache_key, page);

        if !cache_file.exists() {
            return Ok(None);
        }

        let metadata = match std::fs::metadata(&cache_file) {
            Ok(m) => m,
            Err(e) => return Err(anyhow!("failed to read cache file metadata: {}", e)),
        };

        let modified = match metadata.modified() {
            Ok(t) => t,
            Err(e) => return Err(anyhow!("failed to get cache file modification time: {}", e)),
        };

        let age = match SystemTime::now().duration_since(modified) {
            Ok(d) => d,
            Err(_) => return Ok(None), // Future timestamp means invalid
        };

        // Cache expires after 1 hour
        if age > Duration::from_secs(3600) {
            return Ok(None);
        }

        let content = match std::fs::read_to_string(&cache_file) {
            Ok(c) => c,
            Err(e) => return Err(anyhow!("failed to read cache file: {}", e)),
        };

        match serde_json::from_str::<SearchResponse>(&content) {
            Ok(response) => Ok(Some(response)),
            Err(_e) => {
                // Corrupted cache, treat as miss
                let _ = std::fs::remove_file(&cache_file);
                Ok(None)
            }
        }
    }

    /// Caches a search response to disk.
    pub async fn put_cached_search(
        &self,
        cache_key: &str,
        page: u32,
        response: &SearchResponse,
    ) -> anyhow::Result<()> {
        let cache_file = self.cache_file_path(cache_key, page);

        // Ensure parent directory exists
        if let Some(parent) = cache_file.parent() {
            std::fs::create_dir_all(parent).context("failed to create API cache directory")?;
        }

        let content = serde_json::to_string_pretty(response)
            .context("failed to serialize search response")?;

        std::fs::write(&cache_file, content).context("failed to write API cache file")?;

        Ok(())
    }

    /// Returns the path for an API cache file.
    fn cache_file_path(&self, cache_key: &str, page: u32) -> PathBuf {
        self.api_cache_dir
            .join(cache_key)
            .join(format!("page_{}.json", page))
    }
}

/// Downloads a single thumbnail, ignoring errors gracefully.
async fn download_thumbnail(client: &reqwest::Client, cache: &Cache, wallpaper: &Wallpaper) {
    let path = cache.thumbnail_path(&wallpaper.id, &wallpaper.thumbs.original);
    let tmp_path = path.with_extension("tmp");

    let result = download_file(client, &wallpaper.thumbs.original, &tmp_path).await;

    match result {
        Ok(()) => {
            if let Err(e) = std::fs::rename(&tmp_path, &path) {
                eprintln!(
                    "warning: failed to rename thumbnail {}: {}",
                    wallpaper.id, e
                );
                let _ = std::fs::remove_file(&tmp_path);
            }
        }
        Err(e) => {
            eprintln!(
                "warning: failed to download thumbnail {}: {}",
                wallpaper.id, e
            );
            let _ = std::fs::remove_file(&tmp_path);
        }
    }
}

/// Downloads a file to a temp path.
async fn download_file(client: &reqwest::Client, url: &str, dest: &Path) -> anyhow::Result<()> {
    let response = client
        .get(url)
        .send()
        .await
        .with_context(|| format!("failed to request {url}"))?;

    if !response.status().is_success() {
        return Err(anyhow!("HTTP error {} for {url}", response.status()));
    }

    let bytes = response
        .bytes()
        .await
        .context("failed to read response body")?;

    std::fs::write(dest, &bytes).context(format!("failed to write to {:?}", dest))?;

    Ok(())
}

/// Extracts the file extension from a URL, defaulting to "jpg" if none found.
fn extract_extension(url: &str) -> Option<String> {
    // Strip query string and fragment before extracting
    let clean = url.split('?').next().unwrap_or(url);
    let clean = clean.split('#').next().unwrap_or(clean);
    let after_last_slash = clean.rsplit('/').next()?;
    if let Some(dot_pos) = after_last_slash.rfind('.') {
        let ext = &after_last_slash[dot_pos + 1..];
        if ext.chars().all(|c| c.is_alphanumeric()) && ext.len() <= 10 {
            return Some(ext.to_lowercase());
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_extension() {
        assert_eq!(
            extract_extension("https://example.com/image.png"),
            Some("png".to_string())
        );
        assert_eq!(
            extract_extension("https://example.com/image.JPEG"),
            Some("jpeg".to_string())
        );
        assert_eq!(extract_extension("https://example.com/image"), None);
        assert_eq!(
            extract_extension("https://example.com/path/to.image.webp?query=1"),
            Some("webp".to_string())
        );
    }
}
