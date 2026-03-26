//! Application state machine and event loop.
//!
//! Coordinates between terminal events, background tasks (search, thumbnail
//! loading, downloads), and the TUI rendering pipeline.

use std::collections::HashMap;
use std::path::PathBuf;

use anyhow::{Context, Result};
use crossterm::event::{Event, EventStream, KeyCode, KeyEvent, KeyModifiers};
use futures::StreamExt;
use image::DynamicImage;
use ratatui::DefaultTerminal;
use ratatui_image::picker::{Picker, ProtocolType};
use ratatui_image::protocol::StatefulProtocol;
use tokio::sync::mpsc;

use crate::api::{SearchParams, SearchResponse, Sorting, WallhavenClient, Wallpaper};
use crate::cache::Cache;
use crate::config::Config;

// ---------------------------------------------------------------------------
// Resolution / filter presets
// ---------------------------------------------------------------------------

/// Resolution presets organized by aspect ratio (name, resolutions).
pub const ASPECT_RATIOS: &[(&str, &[&str])] = &[
    (
        "16:9",
        &[
            "1280x720",
            "1600x900",
            "1920x1080",
            "2560x1440",
            "3840x2160",
        ],
    ),
    (
        "16:10",
        &[
            "1280x800",
            "1600x1000",
            "1920x1200",
            "2560x1600",
            "3840x2400",
        ],
    ),
    ("Ultrawide", &["2560x1080", "3440x1440", "3840x1600"]),
    (
        "4:3",
        &[
            "1280x960",
            "1600x1200",
            "1920x1440",
            "2560x1920",
            "3840x2880",
        ],
    ),
    (
        "5:4",
        &[
            "1280x1024",
            "1600x1280",
            "1920x1536",
            "2560x2048",
            "3840x3072",
        ],
    ),
];

/// Minimum resolution presets for atleast cycling.
const ATLEAST_PRESETS: &[&str] = &["1920x1080", "2560x1440", "3840x2160"];

/// Toplist time range values accepted by the Wallhaven API.
const TOPLIST_RANGES: &[&str] = &["1d", "3d", "1w", "1M", "3M", "6M", "1y"];

/// Maximum in-memory cached decoded thumbnails.
const MAX_THUMB_CACHE: usize = 120;
/// Maximum in-memory cached decoded full-size previews.
const MAX_PREVIEW_CACHE: usize = 5;

// ---------------------------------------------------------------------------
// Grid layout (computed from terminal area each frame)
// ---------------------------------------------------------------------------

/// Computed grid layout dimensions — derived from the available area each frame.
pub struct GridLayout {
    pub cols: usize,
    pub cell_w: u16,
    pub cell_h: u16,
    pub visible_rows: usize,
}

fn is_valid_filter_bitfield(value: &str) -> bool {
    value.len() == 3 && value.chars().all(|c| matches!(c, '0' | '1')) && value.contains('1')
}

fn sanitize_filter_bitfield(value: &str, fallback: &str) -> String {
    if is_valid_filter_bitfield(value) {
        value.to_string()
    } else {
        fallback.to_string()
    }
}

// ---------------------------------------------------------------------------
// Background task messages
// ---------------------------------------------------------------------------

/// Events produced by background tasks and delivered to the main loop.
enum BgEvent {
    SearchResult {
        generation: u64,
        result: Result<SearchResponse>,
    },
    ThumbnailReady {
        generation: u64,
        id: String,
        index: usize,
        image: DynamicImage,
    },
    PreviewReady {
        generation: u64,
        preview_index: usize,
        image: DynamicImage,
    },
    PreviewFailed {
        generation: u64,
        msg: String,
    },
    DownloadDone {
        id: String,
        path: PathBuf,
    },
    DownloadFailed {
        id: String,
        error: String,
    },
    WallpaperCommandDone(String),
}

// ---------------------------------------------------------------------------
// App state
// ---------------------------------------------------------------------------

/// Which view the user is in.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    /// Thumbnail grid browser.
    Grid,
    /// Full-size image preview.
    Preview,
    /// Text input for search query.
    Search,
    /// Help overlay.
    Help,
}

/// One cell in the thumbnail grid.
pub struct GridItem {
    pub wallpaper: Wallpaper,
    pub protocol: Option<StatefulProtocol>,
    pub marked: bool,
}

pub struct App {
    // -- Dependencies --
    pub config: Config,
    pub cache: Cache,
    client: WallhavenClient,
    http: reqwest::Client,
    pub picker: Picker,
    bg_tx: mpsc::UnboundedSender<BgEvent>,
    bg_rx: mpsc::UnboundedReceiver<BgEvent>,

    // -- View state --
    pub mode: Mode,
    pub should_quit: bool,

    // -- Search / results --
    pub params: SearchParams,
    pub last_response: Option<SearchResponse>,
    pub grid: Vec<GridItem>,
    pub selected: usize,
    pub scroll_row: usize,

    // -- Generation counters (for stale event detection) --
    search_gen: u64,
    preview_gen: u64,

    // -- Preview --
    pub preview_protocol: Option<StatefulProtocol>,
    pub preview_loading: bool,
    pub preview_index: usize,

    // -- Search input --
    pub search_input: String,
    pub search_cursor: usize,

    // -- Status --
    pub status: String,
    pub loading: bool,
    pub last_grid_cols: usize,

    // -- In-memory image cache (avoids re-decode from disk on revisit) --
    thumbnail_cache: HashMap<String, DynamicImage>,
    preview_cache: HashMap<String, DynamicImage>,

    // -- Resolution filter tracking --
    /// Index into ATLEAST_PRESETS. None = atleast off.
    pub atleast_idx: Option<usize>,
    /// Index into ASPECT_RATIOS. None = no aspect ratio filter.
    pub aspect_idx: Option<usize>,
}

impl App {
    pub fn new(config: Config, cache: Cache, picker: Picker) -> Self {
        let client = WallhavenClient::new(config.api.key.clone());
        let http = reqwest::Client::builder()
            .user_agent("waldl/0.1")
            .build()
            .expect("reqwest client");
        let (bg_tx, bg_rx) = mpsc::unbounded_channel();

        let atleast = match config.defaults.atleast.as_str() {
            "auto" => detect_monitor_resolution(),
            "" => None,
            v => Some(v.to_string()),
        };
        let atleast_idx = atleast
            .as_deref()
            .and_then(|a| ATLEAST_PRESETS.iter().position(|&p| p == a));

        let params = SearchParams {
            categories: sanitize_filter_bitfield(&config.defaults.categories, "111"),
            purity: sanitize_filter_bitfield(&config.defaults.purity, "100"),
            sorting: config
                .defaults
                .sorting
                .parse()
                .unwrap_or(Sorting::DateAdded),
            toplist_range: config.defaults.toplist_range.clone(),
            atleast,
            ..Default::default()
        };

        Self {
            config,
            cache,
            client,
            http,
            picker,
            bg_tx,
            bg_rx,
            mode: Mode::Grid,
            should_quit: false,
            params,
            last_response: None,
            grid: Vec::new(),
            selected: 0,
            scroll_row: 0,
            search_gen: 0,
            preview_gen: 0,
            preview_protocol: None,
            preview_loading: false,
            preview_index: 0,
            search_input: String::new(),
            search_cursor: 0,
            status: "Press / to search, Enter to browse latest".into(),
            loading: false,
            last_grid_cols: 4,
            thumbnail_cache: HashMap::new(),
            preview_cache: HashMap::new(),
            atleast_idx,
            aspect_idx: None,
        }
    }

    // -- Grid geometry helpers ------------------------------------------------

    /// Compute responsive grid layout from available terminal area.
    /// Cell size scales to fill the area; column count adapts to width.
    pub fn compute_grid_layout(&self, area_width: u16, area_height: u16) -> GridLayout {
        let cols = match area_width {
            0..=59 => 2,
            60..=99 => 3,
            100..=159 => 4,
            160..=219 => 5,
            _ => 6,
        };
        let cell_w = area_width / cols as u16;
        // Terminal cells are ~2x tall as wide; 0.45 ratio produces good thumbnails
        let cell_h = ((cell_w as f32) * 0.45).round().max(6.0) as u16;
        let visible_rows = if cell_h > 0 {
            (area_height / cell_h).max(1) as usize
        } else {
            1
        };
        GridLayout {
            cols,
            visible_rows,
            cell_w,
            cell_h,
        }
    }

    /// Total rows needed for the entire grid.
    pub fn grid_total_rows(&self, cols: usize) -> usize {
        if self.grid.is_empty() || cols == 0 {
            return 0;
        }
        self.grid.len().div_ceil(cols)
    }

    // -- Pagination helpers ---------------------------------------------------

    pub fn current_page(&self) -> u32 {
        self.params.page
    }

    pub fn last_page(&self) -> u32 {
        self.last_response
            .as_ref()
            .map(|r| r.meta.last_page)
            .unwrap_or(1)
    }

    pub fn total_results(&self) -> u32 {
        self.last_response
            .as_ref()
            .map(|r| r.meta.total)
            .unwrap_or(0)
    }

    // -- Search ---------------------------------------------------------------

    fn trigger_search(&mut self) {
        if !is_valid_filter_bitfield(&self.params.purity) {
            self.loading = false;
            self.status = "Search blocked: enable at least one purity".into();
            return;
        }
        if !is_valid_filter_bitfield(&self.params.categories) {
            self.loading = false;
            self.status = "Search blocked: enable at least one category".into();
            return;
        }

        self.search_gen += 1;
        self.loading = true;
        self.status = format!("Searching page {}...", self.params.page);
        self.grid.clear();
        self.selected = 0;
        self.scroll_row = 0;

        let generation = self.search_gen;
        let client = self.client.clone();
        let cache = self.cache.clone();
        let params = self.params.clone();
        let api_key = self.config.api.key.clone();
        let tx = self.bg_tx.clone();

        tokio::spawn(async move {
            // Try cache first
            let cache_key = params.cache_key(api_key.as_deref());
            if let Ok(Some(cached)) = cache.get_cached_search(&cache_key, params.page).await {
                let _ = tx.send(BgEvent::SearchResult {
                    generation,
                    result: Ok(cached),
                });
                return;
            }
            let result = client.search(&params).await;
            if let Ok(ref resp) = result {
                let _ = cache.put_cached_search(&cache_key, params.page, resp).await;
            }
            let _ = tx.send(BgEvent::SearchResult { generation, result });
        });
    }

    fn handle_search_result(&mut self, result: Result<SearchResponse>) {
        self.loading = false;
        match result {
            Ok(resp) => {
                let count = resp.data.len();
                let total = resp.meta.total;
                let page = resp.meta.current_page;
                let last = resp.meta.last_page;
                self.status = format!("{count} wallpapers (page {page}/{last}, {total} total)");

                // Populate grid items (protocols loaded later via bg tasks)
                self.grid = resp
                    .data
                    .iter()
                    .map(|w| GridItem {
                        wallpaper: w.clone(),
                        protocol: None,
                        marked: false,
                    })
                    .collect();

                self.last_response = Some(resp);
                self.start_thumbnail_loading();
            }
            Err(e) => {
                let details = format!("{e:#}");
                let log_path = self.cache.debug_log_path();
                let _ = self.cache.append_debug_log(&format!(
                    concat!(
                        "search failed\n",
                        "query={:?}\n",
                        "sorting={}\n",
                        "purity={}\n",
                        "categories={}\n",
                        "page={}\n",
                        "atleast={:?}\n",
                        "resolutions={:?}\n",
                        "error={}\n"
                    ),
                    self.params.query,
                    self.params.sorting,
                    self.params.purity,
                    self.params.categories,
                    self.params.page,
                    self.params.atleast,
                    self.params.resolutions,
                    details
                ));
                self.status = format!("Search failed — see {}", log_path.display());
            }
        }
    }

    fn start_thumbnail_loading(&mut self) {
        let generation = self.search_gen;

        // First pass: resolve from in-memory cache (no I/O needed)
        for i in 0..self.grid.len() {
            let id = self.grid[i].wallpaper.id.clone();
            if let Some(cached) = self.thumbnail_cache.get(&id).cloned() {
                let proto = self.picker.new_resize_protocol(cached);
                self.grid[i].protocol = Some(proto);
            }
        }

        // Second pass: spawn bg tasks for uncached items only
        for (i, item) in self.grid.iter().enumerate() {
            if item.protocol.is_some() {
                continue; // already resolved from memory cache
            }
            let cache = self.cache.clone();
            let http = self.http.clone();
            let wallpaper = item.wallpaper.clone();
            let tx = self.bg_tx.clone();
            let wp_id = wallpaper.id.clone();

            tokio::spawn(async move {
                // Download thumbnail if missing on disk
                let path = cache.thumbnail_path(&wallpaper.id, &wallpaper.thumbs.original);
                if !path.exists() {
                    let tmp = path.with_extension("tmp");
                    let dl = async {
                        let resp = http.get(&wallpaper.thumbs.original).send().await?;
                        let bytes = resp.bytes().await?;
                        tokio::fs::write(&tmp, &bytes).await?;
                        tokio::fs::rename(&tmp, &path).await?;
                        Ok::<(), anyhow::Error>(())
                    };
                    if let Err(e) = dl.await {
                        eprintln!("thumb dl failed {}: {e}", wallpaper.id);
                        return;
                    }
                }
                // Decode on blocking thread to avoid starving the runtime
                let path_clone = path.clone();
                let decode_result = tokio::task::spawn_blocking(move || {
                    image::ImageReader::open(&path_clone)
                        .and_then(|r| r.with_guessed_format())
                        .map_err(anyhow::Error::from)
                        .and_then(|r| r.decode().map_err(Into::into))
                })
                .await;
                match decode_result {
                    Ok(Ok(img)) => {
                        let _ = tx.send(BgEvent::ThumbnailReady {
                            generation,
                            id: wp_id,
                            index: i,
                            image: img,
                        });
                    }
                    Ok(Err(e)) => {
                        eprintln!("thumb decode failed {}: {e}", wallpaper.id);
                    }
                    Err(e) => {
                        eprintln!("thumb decode task panicked {}: {e}", wallpaper.id);
                    }
                }
            });
        }
    }

    // -- Preview --------------------------------------------------------------

    fn open_preview(&mut self) {
        if self.grid.is_empty() {
            return;
        }
        self.preview_index = self.selected;
        self.preview_protocol = None;
        self.preview_loading = true;
        self.mode = Mode::Preview;
        self.load_preview_image(self.preview_index);
    }

    /// Open the current wallpaper in an external viewer (xdg-open or configured command).
    /// Downloads the full image first if not cached.
    fn open_external(&mut self) {
        if self.grid.is_empty() {
            return;
        }
        let idx = if self.mode == Mode::Preview {
            self.preview_index
        } else {
            self.selected
        };
        let Some(item) = self.grid.get(idx) else {
            return;
        };
        self.status = format!("Opening {}...", item.wallpaper.id);

        let cache = self.cache.clone();
        let http = self.http.clone();
        let wallpaper = item.wallpaper.clone();
        let preview_cmd = self.config.general.preview_command.clone();
        let tx = self.bg_tx.clone();

        tokio::spawn(async move {
            // Download to cache if needed
            let ext = wallpaper
                .path
                .rsplit('.')
                .next()
                .unwrap_or("jpg")
                .to_string();
            let preview_path = cache
                .cache_dir()
                .join(format!("preview_{}.{}", wallpaper.id, ext));

            if !preview_path.exists() {
                let tmp = preview_path.with_extension(format!("{ext}.tmp"));
                let dl = async {
                    let resp = http.get(&wallpaper.path).send().await?;
                    let bytes = resp.bytes().await?;
                    tokio::fs::write(&tmp, &bytes).await?;
                    tokio::fs::rename(&tmp, &preview_path).await?;
                    Ok::<(), anyhow::Error>(())
                };
                if let Err(e) = dl.await {
                    let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                        "Preview download failed: {e}"
                    )));
                    return;
                }
            }

            // Run the preview command
            let cmd = preview_cmd.replace("{path}", &preview_path.to_string_lossy());
            match tokio::process::Command::new("sh")
                .arg("-c")
                .arg(&cmd)
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                .spawn()
            {
                Ok(_child) => {
                    // Fire and forget — viewer runs independently
                    let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                        "Opened {}",
                        wallpaper.id
                    )));
                }
                Err(e) => {
                    let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                        "Preview command failed: {e}"
                    )));
                }
            }
        });
    }

    fn load_preview_image(&mut self, index: usize) {
        let Some(item) = self.grid.get(index) else {
            return;
        };
        self.preview_gen += 1;
        self.preview_loading = true;
        self.preview_protocol = None;

        // Check in-memory preview cache first
        if let Some(cached) = self.preview_cache.get(&item.wallpaper.id).cloned() {
            let proto = self.picker.new_resize_protocol(cached);
            self.preview_protocol = Some(proto);
            self.preview_loading = false;
            self.preview_index = index;
            return;
        }

        let generation = self.preview_gen;
        let cache = self.cache.clone();
        let http = self.http.clone();
        let wallpaper = item.wallpaper.clone();
        let tx = self.bg_tx.clone();

        tokio::spawn(async move {
            let ext = wallpaper
                .path
                .rsplit('.')
                .next()
                .unwrap_or("jpg")
                .to_string();
            let preview_path = cache
                .cache_dir()
                .join(format!("preview_{}.{}", wallpaper.id, ext));

            if !preview_path.exists() {
                let tmp = preview_path.with_extension(format!("{ext}.tmp"));
                let dl = async {
                    let resp = http.get(&wallpaper.path).send().await?;
                    let bytes = resp.bytes().await?;
                    tokio::fs::write(&tmp, &bytes).await?;
                    tokio::fs::rename(&tmp, &preview_path).await?;
                    Ok::<(), anyhow::Error>(())
                };
                if let Err(e) = dl.await {
                    let _ = tx.send(BgEvent::PreviewFailed {
                        generation,
                        msg: format!("Download failed: {e}"),
                    });
                    return;
                }
            }

            let decode_result = tokio::task::spawn_blocking(move || {
                image::ImageReader::open(&preview_path)
                    .and_then(|r| r.with_guessed_format())
                    .map_err(anyhow::Error::from)
                    .and_then(|r| r.decode().map_err(Into::into))
            })
            .await;
            match decode_result {
                Ok(Ok(img)) => {
                    let _ = tx.send(BgEvent::PreviewReady {
                        generation,
                        preview_index: index,
                        image: img,
                    });
                }
                Ok(Err(e)) => {
                    let _ = tx.send(BgEvent::PreviewFailed {
                        generation,
                        msg: format!("Decode failed: {e}"),
                    });
                }
                Err(e) => {
                    let _ = tx.send(BgEvent::PreviewFailed {
                        generation,
                        msg: format!("Decode task panicked: {e}"),
                    });
                }
            }
        });
    }

    // -- Download / wallpaper set ---------------------------------------------

    fn download_selected(&mut self) {
        let indices: Vec<usize> = if self.grid.iter().any(|g| g.marked) {
            self.grid
                .iter()
                .enumerate()
                .filter(|(_, g)| g.marked)
                .map(|(i, _)| i)
                .collect()
        } else if !self.grid.is_empty() {
            vec![if self.mode == Mode::Preview {
                self.preview_index
            } else {
                self.selected
            }]
        } else {
            return;
        };

        let count = indices.len();
        self.status = format!("Downloading {count} wallpaper(s)...");

        let wallpaper_dir = PathBuf::from(&self.config.general.wallpaper_dir);

        for idx in indices {
            let wallpaper = self.grid[idx].wallpaper.clone();
            let cache = self.cache.clone();
            let http = self.http.clone();
            let dest = wallpaper_dir.clone();
            let tx = self.bg_tx.clone();

            tokio::spawn(async move {
                match cache.download_wallpaper(&http, &wallpaper, &dest).await {
                    Ok(path) => {
                        let _ = tx.send(BgEvent::DownloadDone {
                            id: wallpaper.id,
                            path,
                        });
                    }
                    Err(e) => {
                        let _ = tx.send(BgEvent::DownloadFailed {
                            id: wallpaper.id,
                            error: e.to_string(),
                        });
                    }
                }
            });
        }
    }

    fn set_wallpaper(&mut self) {
        if self.grid.is_empty() {
            return;
        }
        let idx = if self.mode == Mode::Preview {
            self.preview_index
        } else {
            self.selected
        };
        let wallpaper = self.grid[idx].wallpaper.clone();
        let wallpaper_dir = PathBuf::from(&self.config.general.wallpaper_dir);
        let command_template = self.config.general.wallpaper_command.clone();
        let cache = self.cache.clone();
        let http = self.http.clone();
        let tx = self.bg_tx.clone();

        self.status = format!("Setting wallpaper {}...", wallpaper.id);

        tokio::spawn(async move {
            // Download first
            let path = match cache
                .download_wallpaper(&http, &wallpaper, &wallpaper_dir)
                .await
            {
                Ok(p) => p,
                Err(e) => {
                    let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                        "Download failed: {e}"
                    )));
                    return;
                }
            };

            // Run wallpaper command if configured
            if let Some(template) = command_template {
                let cmd = template.replace("{path}", &path.to_string_lossy());
                match tokio::process::Command::new("sh")
                    .arg("-c")
                    .arg(&cmd)
                    .output()
                    .await
                {
                    Ok(output) if output.status.success() => {
                        let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                            "Wallpaper set: {}",
                            wallpaper.id
                        )));
                    }
                    Ok(output) => {
                        let stderr = String::from_utf8_lossy(&output.stderr);
                        let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                            "Command failed: {stderr}"
                        )));
                    }
                    Err(e) => {
                        let _ =
                            tx.send(BgEvent::WallpaperCommandDone(format!("Command error: {e}")));
                    }
                }
            } else {
                let _ = tx.send(BgEvent::WallpaperCommandDone(format!(
                    "Downloaded to {}",
                    path.display()
                )));
            }
        });
    }

    // -- Event handling -------------------------------------------------------

    fn handle_key_grid(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Char('q') | KeyCode::Esc => self.should_quit = true,
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.should_quit = true;
            }
            KeyCode::Char('/') => {
                self.search_input = self.params.query.clone();
                self.search_cursor = self.search_input.len();
                self.mode = Mode::Search;
            }
            KeyCode::Enter => self.trigger_search(),
            // Open external viewer
            KeyCode::Char('o') => self.open_external(),
            // In-terminal preview (toggle)
            KeyCode::Char(' ') | KeyCode::Char('p') => self.open_preview(),
            // Navigation
            KeyCode::Char('h') | KeyCode::Left => self.move_selection(-1, 0),
            KeyCode::Char('l') | KeyCode::Right => self.move_selection(1, 0),
            KeyCode::Char('k') | KeyCode::Up => self.move_selection(0, -1),
            KeyCode::Char('j') | KeyCode::Down => self.move_selection(0, 1),
            // Mark for download
            KeyCode::Char('m') => {
                if let Some(item) = self.grid.get_mut(self.selected) {
                    item.marked = !item.marked;
                }
                self.move_selection(1, 0); // advance after marking
            }
            // Pagination
            KeyCode::Char('n') | KeyCode::PageDown => {
                if self.current_page() < self.last_page() {
                    self.params.page += 1;
                    self.trigger_search();
                }
            }
            KeyCode::Char('N') | KeyCode::PageUp => {
                if self.current_page() > 1 {
                    self.params.page -= 1;
                    self.trigger_search();
                }
            }
            // Download
            KeyCode::Char('d') => self.download_selected(),
            // Set wallpaper
            KeyCode::Char('w') => self.set_wallpaper(),
            // Sorting cycle
            KeyCode::Char('s') => self.cycle_sorting(),
            // Purity toggles
            KeyCode::Char('1') => self.toggle_purity(0),
            KeyCode::Char('2') => self.toggle_purity(1),
            KeyCode::Char('3') => self.toggle_purity(2),
            // Category toggles
            KeyCode::Char('4') => self.toggle_category(0),
            KeyCode::Char('5') => self.toggle_category(1),
            KeyCode::Char('6') => self.toggle_category(2),
            // Resolution / aspect filters
            KeyCode::Char('a') => self.cycle_atleast(),
            KeyCode::Char('r') => self.cycle_aspect_ratio(),
            KeyCode::Char('t') => self.cycle_toplist_range(),
            // Help
            KeyCode::Char('?') => self.mode = Mode::Help,
            _ => {}
        }
    }

    fn handle_key_preview(&mut self, key: KeyEvent) {
        match key.code {
            // Space or Esc close preview
            KeyCode::Char(' ') | KeyCode::Esc | KeyCode::Char('q') => {
                self.mode = Mode::Grid;
                self.preview_protocol = None;
            }
            KeyCode::Char('h') | KeyCode::Left => {
                if self.preview_index > 0 {
                    self.preview_index -= 1;
                    self.load_preview_image(self.preview_index);
                }
            }
            KeyCode::Char('l') | KeyCode::Right => {
                if self.preview_index + 1 < self.grid.len() {
                    self.preview_index += 1;
                    self.load_preview_image(self.preview_index);
                }
            }
            KeyCode::Char('d') => self.download_selected(),
            KeyCode::Char('w') => self.set_wallpaper(),
            KeyCode::Char('m') => {
                if let Some(item) = self.grid.get_mut(self.preview_index) {
                    item.marked = !item.marked;
                }
            }
            KeyCode::Char('o') | KeyCode::Enter => self.open_external(),
            _ => {}
        }
    }

    fn handle_key_search(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc => {
                self.mode = Mode::Grid;
            }
            KeyCode::Enter => {
                self.params.query = self.search_input.clone();
                self.params.page = 1;
                self.mode = Mode::Grid;
                self.trigger_search();
            }
            KeyCode::Backspace => {
                if self.search_cursor > 0 {
                    self.search_cursor -= 1;
                    self.search_input.remove(self.search_cursor);
                }
            }
            KeyCode::Delete => {
                if self.search_cursor < self.search_input.len() {
                    self.search_input.remove(self.search_cursor);
                }
            }
            KeyCode::Left => {
                self.search_cursor = self.search_cursor.saturating_sub(1);
            }
            KeyCode::Right => {
                self.search_cursor = (self.search_cursor + 1).min(self.search_input.len());
            }
            KeyCode::Home => self.search_cursor = 0,
            KeyCode::End => self.search_cursor = self.search_input.len(),
            KeyCode::Char(c) => {
                self.search_input.insert(self.search_cursor, c);
                self.search_cursor += 1;
            }
            _ => {}
        }
    }

    fn handle_key_help(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc | KeyCode::Char('q') | KeyCode::Char('?') => {
                self.mode = Mode::Grid;
            }
            _ => {}
        }
    }

    fn move_selection(&mut self, dx: i32, dy: i32) {
        if self.grid.is_empty() {
            return;
        }
        // We don't know terminal width here, so store cols on last draw.
        // For now use a reasonable default; the draw function will clamp.
        let cols = self.last_grid_cols.max(1);
        let row = self.selected / cols;
        let col = self.selected % cols;
        let new_col = (col as i32 + dx).clamp(0, cols as i32 - 1) as usize;
        let total_rows = self.grid_total_rows(cols);
        let new_row = (row as i32 + dy).clamp(0, total_rows as i32 - 1) as usize;
        let new_idx = new_row * cols + new_col;
        self.selected = new_idx.min(self.grid.len().saturating_sub(1));
    }

    fn cycle_sorting(&mut self) {
        use Sorting::*;
        self.params.sorting = match self.params.sorting {
            DateAdded => Relevance,
            Relevance => Random,
            Random => Views,
            Views => Favorites,
            Favorites => Toplist,
            Toplist => DateAdded,
        };
        self.status = format!("Sorting: {}", self.params.sorting);
        // Auto-search if we already have results
        if self.last_response.is_some() {
            self.params.page = 1;
            self.trigger_search();
        }
    }

    fn toggle_purity(&mut self, bit: usize) {
        let mut chars: Vec<char> = self.params.purity.chars().collect();
        if bit < chars.len() {
            chars[bit] = if chars[bit] == '1' { '0' } else { '1' };
            let next: String = chars.iter().collect();
            let labels = ["SFW", "Sketchy", "NSFW"];

            if !is_valid_filter_bitfield(&next) {
                self.status = "Keep at least one purity enabled".into();
                return;
            }

            self.params.purity = next;
            let state = if self.params.purity.chars().nth(bit) == Some('1') {
                "ON"
            } else {
                "OFF"
            };
            self.status = format!("{}: {state}", labels[bit]);
            if self.last_response.is_some() {
                self.params.page = 1;
                self.trigger_search();
            }
        }
    }

    fn toggle_category(&mut self, bit: usize) {
        let mut chars: Vec<char> = self.params.categories.chars().collect();
        if bit < chars.len() {
            chars[bit] = if chars[bit] == '1' { '0' } else { '1' };
            let next: String = chars.iter().collect();
            let labels = ["General", "Anime", "People"];

            if !is_valid_filter_bitfield(&next) {
                self.status = "Keep at least one category enabled".into();
                return;
            }

            self.params.categories = next;
            let state = if self.params.categories.chars().nth(bit) == Some('1') {
                "ON"
            } else {
                "OFF"
            };
            self.status = format!("{}: {state}", labels[bit]);
            if self.last_response.is_some() {
                self.params.page = 1;
                self.trigger_search();
            }
        }
    }

    fn cycle_atleast(&mut self) {
        // Atleast and aspect ratio are mutually exclusive
        self.aspect_idx = None;
        self.params.resolutions = None;

        self.atleast_idx = match self.atleast_idx {
            None => Some(0),
            Some(i) if i + 1 < ATLEAST_PRESETS.len() => Some(i + 1),
            Some(_) => None,
        };

        self.params.atleast = self.atleast_idx.map(|i| ATLEAST_PRESETS[i].to_string());
        let display = self.params.atleast.as_deref().unwrap_or("off");
        self.status = format!("Min resolution: {display}");

        if self.last_response.is_some() {
            self.params.page = 1;
            self.trigger_search();
        }
    }

    fn cycle_aspect_ratio(&mut self) {
        // Aspect ratio and atleast are mutually exclusive
        self.atleast_idx = None;
        self.params.atleast = None;

        self.aspect_idx = match self.aspect_idx {
            None => Some(0),
            Some(i) if i + 1 < ASPECT_RATIOS.len() => Some(i + 1),
            Some(_) => None,
        };

        if let Some(idx) = self.aspect_idx {
            let (name, resolutions) = ASPECT_RATIOS[idx];
            self.params.resolutions = Some(resolutions.join(","));
            self.status = format!("Aspect: {name}");
        } else {
            self.params.resolutions = None;
            self.status = "Aspect ratio: off".into();
        }

        if self.last_response.is_some() {
            self.params.page = 1;
            self.trigger_search();
        }
    }

    fn cycle_toplist_range(&mut self) {
        let current_idx = TOPLIST_RANGES
            .iter()
            .position(|&r| r == self.params.toplist_range)
            .unwrap_or(0);
        let next_idx = (current_idx + 1) % TOPLIST_RANGES.len();
        self.params.toplist_range = TOPLIST_RANGES[next_idx].to_string();
        self.status = format!("Toplist range: {}", self.params.toplist_range);

        if self.params.sorting == Sorting::Toplist && self.last_response.is_some() {
            self.params.page = 1;
            self.trigger_search();
        }
    }

    // -- Image cache helpers --------------------------------------------------

    fn cache_thumbnail(&mut self, id: String, image: DynamicImage) {
        if self.thumbnail_cache.len() >= MAX_THUMB_CACHE {
            let evict: Vec<String> = self
                .thumbnail_cache
                .keys()
                .take(MAX_THUMB_CACHE / 2)
                .cloned()
                .collect();
            for k in evict {
                self.thumbnail_cache.remove(&k);
            }
        }
        self.thumbnail_cache.insert(id, image);
    }

    fn cache_preview(&mut self, id: String, image: DynamicImage) {
        if self.preview_cache.len() >= MAX_PREVIEW_CACHE {
            let evict: Vec<String> = self
                .preview_cache
                .keys()
                .take(MAX_PREVIEW_CACHE / 2)
                .cloned()
                .collect();
            for k in evict {
                self.preview_cache.remove(&k);
            }
        }
        self.preview_cache.insert(id, image);
    }

    fn handle_resize(&mut self) {
        // Grid boxes already resize via layout recomputation. Rebuild the image
        // protocols from cached decoded images so thumbnails/previews scale too.
        for item in &mut self.grid {
            if let Some(cached) = self.thumbnail_cache.get(&item.wallpaper.id).cloned() {
                item.protocol = Some(self.picker.new_resize_protocol(cached));
            }
        }

        if self.mode == Mode::Preview
            && let Some(item) = self.grid.get(self.preview_index)
            && let Some(cached) = self.preview_cache.get(&item.wallpaper.id).cloned()
        {
            self.preview_protocol = Some(self.picker.new_resize_protocol(cached));
            self.preview_loading = false;
        }
    }

    /// Current resolution filter display string for the header.
    pub fn resolution_display(&self) -> String {
        if let Some(idx) = self.aspect_idx {
            ASPECT_RATIOS[idx].0.to_string()
        } else if let Some(ref res) = self.params.atleast {
            format!("≥{res}")
        } else {
            String::new()
        }
    }

    // -- Background event processing ------------------------------------------

    fn process_bg_event(&mut self, ev: BgEvent) {
        match ev {
            BgEvent::SearchResult { generation, result } => {
                if generation == self.search_gen {
                    self.handle_search_result(result);
                }
                // else: stale response from a previous search — drop it
            }
            BgEvent::ThumbnailReady {
                generation,
                id,
                index,
                image,
            } => {
                // Accept only if generation matches AND the grid slot still
                // holds the same wallpaper (guards against index reuse).
                let matches = generation == self.search_gen
                    && self
                        .grid
                        .get(index)
                        .is_some_and(|item| item.wallpaper.id == id);
                if matches {
                    // Cache before taking mutable borrow on grid
                    self.cache_thumbnail(id, image.clone());
                    let proto = self.picker.new_resize_protocol(image);
                    self.grid[index].protocol = Some(proto);
                }
            }
            BgEvent::PreviewReady {
                generation,
                preview_index,
                image,
            } => {
                if generation == self.preview_gen {
                    // Cache before taking borrow on grid
                    if let Some(wp_id) = self
                        .grid
                        .get(preview_index)
                        .map(|item| item.wallpaper.id.clone())
                    {
                        self.cache_preview(wp_id, image.clone());
                    }
                    let proto = self.picker.new_resize_protocol(image);
                    self.preview_protocol = Some(proto);
                    self.preview_loading = false;
                    self.preview_index = preview_index;
                }
            }
            BgEvent::PreviewFailed { generation, msg } => {
                if generation == self.preview_gen {
                    self.preview_loading = false;
                    self.status = msg;
                }
            }
            BgEvent::DownloadDone { id, path } => {
                if let Some(item) = self.grid.iter_mut().find(|g| g.wallpaper.id == id) {
                    item.marked = false;
                }
                self.status = format!("Downloaded: {}", path.display());
            }
            BgEvent::DownloadFailed { id, error } => {
                self.status = format!("Download failed ({}): {}", id, error);
            }
            BgEvent::WallpaperCommandDone(msg) => {
                self.status = msg;
            }
        }
    }
}

/// Detect the primary monitor's native resolution from `/sys/class/drm/`.
/// Reads the first connected display's preferred mode — no external tools needed.
fn detect_monitor_resolution() -> Option<String> {
    let drm = std::path::Path::new("/sys/class/drm");
    let mut entries: Vec<_> = std::fs::read_dir(drm)
        .ok()?
        .filter_map(|e| e.ok())
        .collect();
    // Prefer external monitors over eDP.
    entries.sort_by_key(|e| {
        let name = e.file_name();
        let name = name.to_string_lossy();
        (name.contains("eDP"), name.to_string())
    });

    for entry in &entries {
        let path = entry.path();
        let status = std::fs::read_to_string(path.join("status")).unwrap_or_default();
        if status.trim() != "connected" {
            continue;
        }
        let modes = std::fs::read_to_string(path.join("modes")).unwrap_or_default();
        if let Some(mode) = modes.lines().next() {
            let mode = mode.trim();
            if mode.contains('x')
                && mode.split('x').count() == 2
                && mode.split('x').all(|p| p.parse::<u32>().is_ok())
            {
                return Some(mode.to_string());
            }
        }
    }
    None
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

pub async fn run(config: Config, cache: Cache) -> Result<()> {
    // ratatui-image docs: from_query_stdio "should be called after entering
    // alternate screen but before reading terminal events."
    let mut terminal = ratatui::init();

    let mut picker = Picker::from_query_stdio().unwrap_or_else(|e| {
        eprintln!("warning: protocol detection failed ({e}), inferring from $TERM");
        #[allow(deprecated)] // no non-deprecated way to set font size on Picker
        Picker::from_fontsize(guess_font_size())
    });

    // Safety net: if probe returned halfblocks but $TERM says otherwise, override.
    if picker.protocol_type() == ProtocolType::Halfblocks
        && let Some(proto) = infer_protocol_from_env()
    {
        eprintln!("waldl: overriding halfblocks -> {proto:?} (from $TERM)");
        picker.set_protocol_type(proto);
    }

    eprintln!(
        "waldl: protocol={:?} font={}x{}",
        picker.protocol_type(),
        picker.font_size().0,
        picker.font_size().1,
    );

    let result = run_app(&mut terminal, config, cache, picker).await;
    ratatui::restore();
    result
}

/// Infer graphics protocol from $TERM / $TERM_PROGRAM environment.
fn infer_protocol_from_env() -> Option<ProtocolType> {
    let term = std::env::var("TERM").unwrap_or_default().to_lowercase();
    let term_program = std::env::var("TERM_PROGRAM")
        .unwrap_or_default()
        .to_lowercase();

    if term.contains("kitty") || term_program.contains("kitty") {
        return Some(ProtocolType::Kitty);
    }
    if term_program.contains("wezterm") {
        return Some(ProtocolType::Kitty);
    }
    if term_program.contains("ghostty") {
        return Some(ProtocolType::Kitty);
    }
    // foot supports SIXEL
    if term.contains("foot") || term_program.contains("foot") {
        return Some(ProtocolType::Sixel);
    }
    if term_program.contains("iterm") {
        return Some(ProtocolType::Iterm2);
    }
    None
}

/// Best-effort font size when terminal query fails.
fn guess_font_size() -> (u16, u16) {
    // Try to get terminal pixel size from ioctl, fall back to common default.
    // Most modern terminals report pixel size via TIOCGWINSZ.
    use std::os::fd::AsRawFd;
    let fd = std::io::stdout().as_raw_fd();
    // winsize struct: rows, cols, xpixel, ypixel (all u16)
    let mut ws: libc::winsize = unsafe { std::mem::zeroed() };
    let ret = unsafe { libc::ioctl(fd, libc::TIOCGWINSZ, &mut ws) };
    if ret == 0 && ws.ws_xpixel > 0 && ws.ws_ypixel > 0 && ws.ws_col > 0 && ws.ws_row > 0 {
        let fw = ws.ws_xpixel / ws.ws_col;
        let fh = ws.ws_ypixel / ws.ws_row;
        if fw > 0 && fh > 0 {
            return (fw, fh);
        }
    }
    (8, 16) // conservative fallback
}

async fn run_app(
    terminal: &mut DefaultTerminal,
    config: Config,
    cache: Cache,
    picker: Picker,
) -> Result<()> {
    let mut app = App::new(config, cache, picker);
    app.status = format!(
        "Protocol: {:?} | / to search, Enter to browse",
        app.picker.protocol_type()
    );
    let mut event_stream = EventStream::new();

    loop {
        terminal
            .draw(|frame| crate::ui::draw(frame, &mut app))
            .context("draw failed")?;

        if app.should_quit {
            return Ok(());
        }

        // Wait for either a terminal event or a background event.
        tokio::select! {
            maybe_event = event_stream.next() => {
                if let Some(Ok(ev)) = maybe_event {
                    match ev {
                        Event::Key(key) => match app.mode {
                            Mode::Grid => app.handle_key_grid(key),
                            Mode::Preview => app.handle_key_preview(key),
                            Mode::Search => app.handle_key_search(key),
                            Mode::Help => app.handle_key_help(key),
                        },
                        Event::Resize(_, _) => app.handle_resize(),
                        _ => {}
                    }
                }
            }
            Some(bg_ev) = app.bg_rx.recv() => {
                app.process_bg_event(bg_ev);
                // Drain any queued bg events to batch UI updates
                while let Ok(ev) = app.bg_rx.try_recv() {
                    app.process_bg_event(ev);
                }
            }
        }
    }
}
