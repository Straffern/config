//! Wallhaven API client for fetching and searching wallpapers.
//!
//! API docs: <https://wallhaven.cc/help/api>

use std::fmt;
use std::str::FromStr;

use anyhow::{Context, anyhow};
use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// API response types (match Wallhaven API v1)
// ---------------------------------------------------------------------------

/// Full search response from Wallhaven API.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResponse {
    pub data: Vec<Wallpaper>,
    pub meta: SearchMeta,
}

/// Pagination and query metadata.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchMeta {
    #[serde(deserialize_with = "deserialize_u32_from_number_or_string")]
    pub current_page: u32,
    #[serde(deserialize_with = "deserialize_u32_from_number_or_string")]
    pub last_page: u32,
    #[serde(deserialize_with = "deserialize_u32_from_number_or_string")]
    pub per_page: u32,
    #[serde(deserialize_with = "deserialize_u32_from_number_or_string")]
    pub total: u32,
    /// Present when sorting=random with a seed param.
    #[serde(default)]
    pub seed: Option<String>,
}

fn deserialize_u32_from_number_or_string<'de, D>(
    deserializer: D,
) -> std::result::Result<u32, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use serde::de::{self, Visitor};

    struct U32Visitor;

    impl<'de> Visitor<'de> for U32Visitor {
        type Value = u32;

        fn expecting(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            f.write_str("u32 number or string")
        }

        fn visit_u64<E>(self, value: u64) -> std::result::Result<u32, E>
        where
            E: de::Error,
        {
            u32::try_from(value)
                .map_err(|_| E::custom(format!("value out of range for u32: {value}")))
        }

        fn visit_i64<E>(self, value: i64) -> std::result::Result<u32, E>
        where
            E: de::Error,
        {
            let value = u64::try_from(value)
                .map_err(|_| E::custom(format!("negative value for u32: {value}")))?;
            u32::try_from(value)
                .map_err(|_| E::custom(format!("value out of range for u32: {value}")))
        }

        fn visit_str<E>(self, value: &str) -> std::result::Result<u32, E>
        where
            E: de::Error,
        {
            value
                .parse::<u32>()
                .map_err(|e| E::custom(format!("invalid u32 string {value:?}: {e}")))
        }

        fn visit_string<E>(self, value: String) -> std::result::Result<u32, E>
        where
            E: de::Error,
        {
            self.visit_str(&value)
        }
    }

    deserializer.deserialize_any(U32Visitor)
}

/// A single wallpaper result.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Wallpaper {
    pub id: String,
    pub url: String,
    /// Available in newer API versions.
    #[serde(default, alias = "short_url")]
    pub short_url: Option<String>,
    pub views: u64,
    pub favorites: u64,
    pub purity: String,
    pub category: String,
    pub dimension_x: u32,
    pub dimension_y: u32,
    pub resolution: String,
    pub file_size: u64,
    pub file_type: String,
    pub created_at: String,
    #[serde(default)]
    pub colors: Vec<String>,
    /// Remote path to the full image file.
    pub path: String,
    pub thumbs: Thumbs,
}

/// Thumbnail variants for a wallpaper.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Thumbs {
    pub large: String,
    pub original: String,
    pub small: String,
}

// ---------------------------------------------------------------------------
// Search parameters (domain type — NOT a serde struct)
// ---------------------------------------------------------------------------

/// Search/filter parameters for wallpaper queries.
#[derive(Debug, Clone, PartialEq)]
pub struct SearchParams {
    pub query: String,
    pub categories: String,
    pub purity: String,
    pub sorting: Sorting,
    pub order: String,
    pub toplist_range: String,
    /// Minimum resolution string (e.g. "1920x1080"), or None.
    pub atleast: Option<String>,
    /// Comma-separated resolution list, or None.
    pub resolutions: Option<String>,
    pub page: u32,
    pub seed: Option<String>,
}

impl Default for SearchParams {
    fn default() -> Self {
        Self {
            query: String::new(),
            categories: "111".to_string(),
            purity: "100".to_string(),
            sorting: Sorting::DateAdded,
            order: "desc".to_string(),
            toplist_range: "1M".to_string(),
            atleast: None,
            resolutions: None,
            page: 1,
            seed: None,
        }
    }
}

/// Sort order accepted by the Wallhaven API.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Sorting {
    DateAdded,
    Relevance,
    Random,
    Views,
    Favorites,
    Toplist,
}

impl fmt::Display for Sorting {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            Sorting::DateAdded => "date_added",
            Sorting::Relevance => "relevance",
            Sorting::Random => "random",
            Sorting::Views => "views",
            Sorting::Favorites => "favorites",
            Sorting::Toplist => "toplist",
        };
        write!(f, "{s}")
    }
}

impl FromStr for Sorting {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> anyhow::Result<Self> {
        match s {
            "date_added" => Ok(Sorting::DateAdded),
            "relevance" => Ok(Sorting::Relevance),
            "random" => Ok(Sorting::Random),
            "views" => Ok(Sorting::Views),
            "favorites" => Ok(Sorting::Favorites),
            "toplist" => Ok(Sorting::Toplist),
            _ => Err(anyhow!("unknown sorting value: {s}")),
        }
    }
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

const BASE_URL: &str = "https://wallhaven.cc/api/v1";
const USER_AGENT: &str = "waldl/0.1";

/// Wallhaven API client with optional authentication.
#[derive(Debug, Clone)]
pub struct WallhavenClient {
    http: reqwest::Client,
    api_key: Option<String>,
}

impl WallhavenClient {
    /// Create a new client. If `api_key` is provided it will be appended as
    /// `apikey=<KEY>` query parameter, matching Wallhaven API docs.
    pub fn new(api_key: Option<String>) -> Self {
        let http = reqwest::Client::builder()
            .user_agent(USER_AGENT)
            .build()
            .expect("reqwest client builder is always valid");
        Self { http, api_key }
    }

    /// Search wallpapers with the given parameters.
    pub async fn search(&self, params: &SearchParams) -> anyhow::Result<SearchResponse> {
        let url = self.build_search_url(params);

        let resp = self
            .http
            .get(&url)
            .send()
            .await
            .with_context(|| format!("failed to GET {url}"))?;

        let status = resp.status();
        let content_type = resp
            .headers()
            .get(reqwest::header::CONTENT_TYPE)
            .and_then(|v| v.to_str().ok())
            .unwrap_or("<missing>")
            .to_string();
        let body_text = resp
            .text()
            .await
            .context("failed to read Wallhaven API response body")?;
        let body_snippet = body_text.split_whitespace().collect::<Vec<_>>().join(" ");
        let body_snippet: String = body_snippet.chars().take(240).collect();

        if status.as_u16() == 429 {
            return Err(anyhow!(
                "Wallhaven API rate limit exceeded (45 req/min). Wait before retrying."
            ));
        }
        if status.as_u16() == 401 {
            return Err(anyhow!(
                "API request unauthorized — check your Wallhaven API key"
            ));
        }
        if !status.is_success() {
            return Err(anyhow!(
                "Wallhaven API returned HTTP {status} (content-type: {content_type}) body: {body_snippet}"
            ));
        }

        serde_json::from_str::<SearchResponse>(&body_text).with_context(|| {
            format!(
                "failed to parse Wallhaven API JSON response (content-type: {content_type}) body: {body_snippet}"
            )
        })
    }

    fn build_search_url(&self, params: &SearchParams) -> String {
        let mut url = format!("{}/search?q={}", BASE_URL, percent_encode(&params.query));
        url.push_str(&format!("&categories={}", params.categories));
        url.push_str(&format!("&purity={}", params.purity));
        url.push_str(&format!("&sorting={}", params.sorting));
        url.push_str(&format!("&order={}", params.order));

        // Wallhaven expects auth as `apikey` query parameter, not an HTTP header.
        if let Some(ref key) = self.api_key
            && !key.is_empty()
        {
            url.push_str("&apikey=");
            url.push_str(&percent_encode(key));
        }

        // toplist_range → topRange param only when sorting by toplist
        if params.sorting == Sorting::Toplist {
            url.push_str(&format!("&topRange={}", params.toplist_range));
        }

        // atleast → only when NOT toplist and no resolutions filter
        if params.sorting != Sorting::Toplist
            && params.resolutions.is_none()
            && let Some(ref res) = params.atleast
        {
            url.push_str(&format!("&atleast={}", res));
        }

        // resolutions take precedence over atleast
        if let Some(ref res) = params.resolutions {
            url.push_str(&format!("&resolutions={}", res));
        }

        url.push_str(&format!("&page={}", params.page));

        if let Some(ref seed) = params.seed {
            url.push_str(&format!("&seed={}", seed));
        }

        url
    }
}

impl SearchParams {
    /// Returns an md5 hex digest of the search parameters + api key.
    /// Used for cache file naming.
    pub fn cache_key(&self, api_key: Option<&str>) -> String {
        let sorting_str = self.sorting.to_string();
        let components: &[&str] = &[
            &self.query,
            &self.categories,
            &self.purity,
            &sorting_str,
            &self.order,
            &self.toplist_range,
            self.atleast.as_deref().unwrap_or(""),
            self.resolutions.as_deref().unwrap_or(""),
            self.seed.as_deref().unwrap_or(""),
            api_key.unwrap_or(""),
        ];
        let mut context = md5::Context::new();
        for part in components {
            context.consume(part.as_bytes());
            context.consume(b"\x00");
        }
        let digest = context.compute();
        format!("{:x}", digest)
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Percent-encode a string for use in query parameters.
fn percent_encode(s: &str) -> String {
    let mut encoded = String::with_capacity(s.len() * 2);
    for byte in s.bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                encoded.push(byte as char);
            }
            b' ' => encoded.push_str("%20"),
            _ => encoded.push_str(&format!("%{:02X}", byte)),
        }
    }
    encoded
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sorting_display_roundtrips() {
        for sorting in [
            Sorting::DateAdded,
            Sorting::Relevance,
            Sorting::Random,
            Sorting::Views,
            Sorting::Favorites,
            Sorting::Toplist,
        ] {
            let s = sorting.to_string();
            assert_eq!(sorting, s.parse().unwrap(), "roundtrip failed for {s}");
        }
    }

    #[test]
    fn search_params_default_is_valid() {
        let params = SearchParams::default();
        assert_eq!(params.query, "");
        assert_eq!(params.categories, "111");
        assert_eq!(params.purity, "100");
        assert_eq!(params.sorting, Sorting::DateAdded);
        assert_eq!(params.page, 1);
    }

    #[test]
    fn build_url_basic() {
        let client = WallhavenClient::new(None);
        let params = SearchParams {
            query: "landscape".to_string(),
            ..Default::default()
        };
        let url = client.build_search_url(&params);
        assert!(url.contains("q=landscape"));
        assert!(url.contains("categories=111"));
        assert!(url.contains("purity=100"));
        assert!(url.contains("sorting=date_added"));
        assert!(url.contains("order=desc"));
        assert!(url.contains("page=1"));
    }

    #[test]
    fn build_url_toplist_includes_toprange() {
        let client = WallhavenClient::new(None);
        let params = SearchParams {
            sorting: Sorting::Toplist,
            toplist_range: "1M".to_string(),
            atleast: Some("1920x1080".to_string()),
            ..Default::default()
        };
        let url = client.build_search_url(&params);
        assert!(url.contains("sorting=toplist"));
        assert!(url.contains("topRange=1M"));
        // atleast should NOT appear when sorting=toplist
        assert!(!url.contains("atleast="));
    }

    #[test]
    fn build_url_resolutions_omits_atleast() {
        let client = WallhavenClient::new(None);
        let params = SearchParams {
            atleast: Some("1920x1080".to_string()),
            resolutions: Some("1920x1080,2560x1440".to_string()),
            ..Default::default()
        };
        let url = client.build_search_url(&params);
        assert!(url.contains("resolutions=1920x1080,2560x1440"));
        // atleast should NOT appear when resolutions is set
        assert!(!url.contains("atleast="));
    }

    #[test]
    fn build_url_includes_seed() {
        let client = WallhavenClient::new(None);
        let params = SearchParams {
            sorting: Sorting::Random,
            seed: Some("abcdef".to_string()),
            ..Default::default()
        };
        let url = client.build_search_url(&params);
        assert!(url.contains("seed=abcdef"));
    }

    #[test]
    fn build_url_includes_apikey_query_param() {
        let client = WallhavenClient::new(Some("abc123".to_string()));
        let url = client.build_search_url(&SearchParams::default());
        assert!(url.contains("apikey=abc123"));
    }

    #[test]
    fn search_meta_accepts_string_numbers() {
        let json = r#"{
            "current_page": 1,
            "last_page": 7,
            "per_page": "24",
            "total": 150,
            "seed": null
        }"#;
        let meta: SearchMeta = serde_json::from_str(json).unwrap();
        assert_eq!(meta.current_page, 1);
        assert_eq!(meta.last_page, 7);
        assert_eq!(meta.per_page, 24);
        assert_eq!(meta.total, 150);
    }

    #[test]
    fn cache_key_deterministic() {
        let params = SearchParams {
            query: "nature".to_string(),
            categories: "111".to_string(),
            ..Default::default()
        };
        let key1 = params.cache_key(None);
        let key2 = params.cache_key(None);
        assert_eq!(key1, key2);
        assert_eq!(key1.len(), 32); // md5 hex
    }

    #[test]
    fn cache_key_differs_by_query() {
        let p1 = SearchParams {
            query: "nature".to_string(),
            ..Default::default()
        };
        let p2 = SearchParams {
            query: "city".to_string(),
            ..Default::default()
        };
        assert_ne!(p1.cache_key(None), p2.cache_key(None));
    }

    #[test]
    fn percent_encode_spaces() {
        assert_eq!(percent_encode("hello world"), "hello%20world");
    }
}
