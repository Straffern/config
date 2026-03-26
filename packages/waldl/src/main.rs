mod api;
mod app;
mod cache;
mod config;
mod ui;

use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    let config = config::Config::load()?;
    let cache = cache::Cache::new()?;
    app::run(config, cache).await
}
