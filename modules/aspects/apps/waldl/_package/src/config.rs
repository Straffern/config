//! Configuration management for waldl.
//!
//! Config is loaded from XDG_CONFIG_HOME/waldl/config.toml (or a fallback path).
//! Missing config files return defaults; invalid TOML returns an error.

use std::path::PathBuf;

use anyhow::{Context, Result};
use directories::ProjectDirs;
use serde::{Deserialize, Serialize};

/// General settings for wallpaper handling.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct GeneralConfig {
    /// Directory where wallpapers are saved.
    pub wallpaper_dir: String,
    /// Command to set wallpaper. `{path}` is replaced with the file path.
    pub wallpaper_command: Option<String>,
    /// Command to preview an image externally. `{path}` is replaced.
    /// Defaults to `xdg-open {path}`.
    pub preview_command: String,
}

impl Default for GeneralConfig {
    fn default() -> Self {
        Self {
            wallpaper_dir: "~/Pictures/wallpapers/wallhaven".into(),
            wallpaper_command: None,
            preview_command: "xdg-open {path}".into(),
        }
    }
}

/// API authentication settings.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
#[derive(Default)]
pub struct ApiConfig {
    /// Wallhaven API key. If empty, requests are unauthenticated.
    pub key: Option<String>,
    /// Path to a file containing the API key (e.g. sops-nix secret).
    /// Read at startup; takes precedence over `key`.
    pub key_file: Option<String>,
}

/// Default values for search parameters.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct DefaultsConfig {
    /// Sorting method: date_added, relevance, random, favorites, toplist, views.
    pub sorting: String,
    /// Purity filter: 100 (SFW), 110 (Sketchy), 111 (SFW+Sketchy), etc.
    pub purity: String,
    /// Category filter: 001 (general), 010 (anime), 100 (people), or combinations.
    pub categories: String,
    /// Minimum resolution. "auto" detects the screen resolution.
    pub atleast: String,
    /// Time range for toplist sorting: 1d, 3d, 1w, 1M, 3M, 6M, 1y.
    pub toplist_range: String,
}

impl Default for DefaultsConfig {
    fn default() -> Self {
        Self {
            sorting: "date_added".into(),
            purity: "100".into(),
            categories: "111".into(),
            atleast: "auto".into(),
            toplist_range: "1M".into(),
        }
    }
}

/// Root configuration structure.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
#[derive(Default)]
pub struct Config {
    pub general: GeneralConfig,
    pub api: ApiConfig,
    pub defaults: DefaultsConfig,
}

impl Config {
    /// Returns the path where the config file is expected to be found.
    /// Falls back to XDG_CONFIG_HOME/waldl/config.toml if ProjectDirs fails.
    pub fn config_path() -> PathBuf {
        ProjectDirs::from("cc", "wallhaven", "waldl")
            .map(|dirs| dirs.config_dir().join("config.toml"))
            .unwrap_or_else(|| {
                std::env::var("XDG_CONFIG_HOME")
                    .map(PathBuf::from)
                    .unwrap_or_else(|_| {
                        dirs::home_dir()
                            .map(|h| h.join(".config"))
                            .unwrap_or_default()
                    })
                    .join("waldl")
                    .join("config.toml")
            })
    }

    /// Loads the configuration from the config file.
    ///
    /// - Missing or empty config file: returns defaults.
    /// - Invalid TOML: returns an error.
    /// - Partial config: merges with defaults via serde.
    pub fn load() -> Result<Config> {
        let path = Self::config_path();

        let mut cfg = if !path.exists() {
            Config::default()
        } else {
            let contents = std::fs::read_to_string(&path)
                .with_context(|| format!("reading config at {}", path.display()))?;

            if contents.trim().is_empty() {
                Config::default()
            } else {
                toml::from_str(&contents)
                    .with_context(|| format!("parsing config at {}", path.display()))?
            }
        };

        // Always expand ~ in wallpaper_dir, including for defaults.
        let expanded = shellexpand::full(&cfg.general.wallpaper_dir)
            .context("expanding ~ in wallpaper_dir")?;
        cfg.general.wallpaper_dir = expanded.into_owned();

        // key_file takes precedence: read secret from file (e.g. sops-nix)
        if let Some(ref path) = cfg.api.key_file {
            let expanded = shellexpand::full(path).context("expanding ~ in api.key_file")?;
            match std::fs::read_to_string(expanded.as_ref()) {
                Ok(contents) => {
                    let trimmed = contents.trim();
                    if !trimmed.is_empty() {
                        cfg.api.key = Some(trimmed.to_string());
                    }
                }
                Err(e) => {
                    eprintln!("warning: failed to read api.key_file {path}: {e}");
                }
            }
        }

        Ok(cfg)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let cfg = Config::default();
        assert_eq!(cfg.general.wallpaper_dir, "~/Pictures/wallpapers/wallhaven");
        assert!(cfg.general.wallpaper_command.is_none());
        assert!(cfg.api.key.is_none());
        assert_eq!(cfg.defaults.sorting, "date_added");
        assert_eq!(cfg.defaults.purity, "100");
        assert_eq!(cfg.defaults.categories, "111");
        assert_eq!(cfg.defaults.atleast, "auto");
        assert_eq!(cfg.defaults.toplist_range, "1M");
    }

    #[test]
    fn test_config_path_always_returns_path() {
        let path = Config::config_path();
        assert!(path.ends_with("waldl/config.toml"));
    }

    #[test]
    fn test_load_expands_tilde_in_defaults() {
        let cfg = Config::load().unwrap();
        // load() must expand ~ even when config file is absent
        assert!(
            !cfg.general.wallpaper_dir.starts_with('~'),
            "wallpaper_dir should be expanded, got: {}",
            cfg.general.wallpaper_dir
        );
    }

    #[test]
    fn test_toml_roundtrip() {
        let cfg = Config::default();
        let serialized = toml::to_string_pretty(&cfg).unwrap();
        let deserialized: Config = toml::from_str(&serialized).unwrap();
        assert_eq!(
            cfg.general.wallpaper_dir,
            deserialized.general.wallpaper_dir
        );
    }
}
