# waldl Specification

## Purpose

`waldl` is a terminal-first wallpaper browser for Wallhaven.

It is designed to let a user:
- search or browse wallpapers from inside a terminal
- inspect results as a responsive thumbnail grid
- preview items in-terminal or in an external viewer
- download or mark multiple wallpapers
- apply a wallpaper through a configurable command
- keep browsing responsive through caching and background work

This document describes the product behavior and the important technical characteristics of the system. It intentionally avoids source-file or function-level detail.

---

## Core Product Model

The application is a stateful terminal UI with four primary interaction modes:

1. **Grid mode**
   - default browsing mode
   - shows search results as a paginated thumbnail grid
   - supports movement, marking, filtering, preview, download, and external open

2. **Preview mode**
   - focuses on one wallpaper at a time
   - shows a larger in-terminal render
   - supports next/previous navigation, mark, download, apply, and external open

3. **Search input mode**
   - captures a free-form query string
   - returning to browsing triggers a new search from page 1

4. **Help mode**
   - documents current keybindings and interaction model

The UI always consists of:
- a header with current query and filter state
- a body area containing the current mode’s content
- a status bar for feedback, progress, and pagination context

---

## User-Facing Capabilities

### Search and Browsing

The application supports:
- empty-query browsing of recent wallpapers
- free-text search
- pagination through result pages
- page-aware total count display when available

A search is defined by the combination of:
- query text
- purity flags
- category flags
- sorting mode
- toplist range when relevant
- minimum resolution, when enabled
- exact-resolution preset selection, when enabled
- page number
- API authentication context

Changing any active filter or sorting option restarts browsing from page 1.

### Sorting

Supported sorting modes:
- date added
- relevance
- random
- views
- favorites
- toplist

When toplist is active, a time range can be selected:
- 1 day
- 3 days
- 1 week
- 1 month
- 3 months
- 6 months
- 1 year

### Purity Filters

Purity is modeled as a three-way toggle set:
- SFW
- Sketchy
- NSFW

The application prevents all three from being disabled at once. A search is blocked if purity becomes invalid.

### Category Filters

Categories are modeled as a three-way toggle set:
- General
- Anime
- People

The application prevents all three from being disabled at once. A search is blocked if categories become invalid.

### Resolution and Aspect Controls

The application supports two mutually exclusive resolution strategies:

1. **Minimum resolution (`atleast`)**
   - cycles through a preset set of minimum sizes
   - includes an `auto` mode driven by the current display resolution

2. **Aspect-ratio resolution presets**
   - selects exact resolution sets grouped by aspect ratio
   - preset groups include:
     - 16:9
     - 16:10
     - Ultrawide
     - 4:3
     - 5:4

Selecting one resolution strategy clears the other.

### Selection and Actions

The grid supports:
- current-item focus
- multi-item marking
- download of marked items
- fallback to current item if nothing is marked

Supported actions:
- in-terminal preview
- external open
- download
- apply wallpaper through configured command

### External Preview and Wallpaper Application

Two configurable command hooks exist:

- **preview command**
  - opens the current full image in an external viewer
  - defaults to a desktop opener command
  - supports replacing `{path}` with the cached file path

- **wallpaper command**
  - runs after ensuring the full wallpaper exists locally
  - supports replacing `{path}` with the local wallpaper file path

This keeps the browser independent of any particular desktop environment or wallpaper daemon.

---

## Configuration Model

The application is XDG-oriented.

### Config Scope

Configuration covers three areas:

1. **General behavior**
   - wallpaper directory
   - wallpaper command
   - preview command

2. **API authentication**
   - inline API key
   - API key file path

3. **Search defaults**
   - sorting
   - purity
   - categories
   - minimum resolution
   - toplist range

### Secret Handling

Authentication supports two models:
- direct key value
- key file path

The key-file model is intended for secret-management systems such as sops-nix. In that model, the config stores only the path to a secret file, not the secret itself.

When both are present, the key file takes precedence.

### Default Resolution Auto-Detection

`atleast = "auto"` means:
- determine the current display’s native or preferred resolution
- use that as the minimum resolution filter

This behavior is based on Linux display metadata rather than a compositor-specific control API.

---

## Terminal Rendering Model

### Protocol Detection

The application supports multiple terminal image rendering strategies and selects the best viable protocol at runtime.

Supported protocol families:
- Kitty graphics protocol
- Sixel
- iTerm2 inline image protocol
- half-block text rendering fallback

Protocol selection is capability-driven, with environment-based fallback heuristics.

### Grid Rendering

Grid cells are responsive and derived from the current terminal area.

The layout recalculates on every draw based on:
- terminal width
- terminal height
- target column count by width tier
- derived cell height

This means:
- the number of columns changes as the terminal grows or shrinks
- boxes always reflow to use available space
- selected row visibility is preserved via scrolling

### Resize Behavior

On terminal resize, the application does two distinct things:

1. **layout recomputation**
   - cell geometry changes immediately

2. **image protocol regeneration**
   - cached decoded images are re-encoded for the new cell area
   - this avoids re-downloading or re-decoding just to adapt to terminal size

### Scaling Behavior

Grid thumbnails and preview images are rendered in scale mode rather than fit-only mode.

Implications:
- images can grow when cells become larger
- images can shrink when cells become smaller
- scaling quality uses a smoother resampling filter rather than nearest-neighbor

Important limitation:
- a thumbnail source cannot gain real detail when enlarged
- larger grid cells can only upscale the available thumbnail pixels
- true sharpness beyond the thumbnail source would require a higher-resolution source to be fetched for the grid

### Thumbnail Source vs Full Image Source

The grid uses Wallhaven thumbnail endpoints, not full wallpaper files.

That is intentional because thumbnails are:
- much smaller
- faster to fetch
- cheaper to decode
- better suited to browsing many results at once

The full wallpaper file is reserved for:
- in-terminal large preview loading
- external open
- download
- wallpaper application

This is a core performance tradeoff.

---

## Caching Model

Caching exists at multiple levels.

### 1. API Response Cache

Search results are cached on disk by a cache key derived from:
- query
- filters
- sorting
- page
- resolution state
- toplist range
- authentication context

Properties:
- page-scoped
- separate by logical search
- time-limited freshness
- stale or corrupted entries are treated as misses

This avoids repeated network calls for recent identical searches.

### 2. Thumbnail Disk Cache

Thumbnail images are cached on disk by wallpaper identifier.

Properties:
- persistent across sessions
- prevents repeated thumbnail downloads
- used as the durable backing store for grid browsing

### 3. Preview Disk Cache

Full-size preview images are cached on disk separately from the download destination.

Properties:
- persistent across sessions
- prevents repeated full-image fetches for external preview or in-terminal preview

### 4. Downloaded Wallpaper Store

Downloaded wallpapers are stored in the configured wallpaper directory.

Properties:
- persistent user-owned library
- separate from internal cache
- download is skipped if the target file already exists

### 5. In-Memory Decoded Image Cache

During a session, decoded images are cached in memory for:
- thumbnails
- previews

Purpose:
- avoid repeated disk reads and image decoding
- allow resize-driven protocol regeneration without re-fetching or re-decoding

This memory cache is bounded and evicts older entries when full.

### 6. Debug Log

A persistent debug log is written under the cache directory.

It records search failures together with request context such as:
- query
- sorting
- purity
- categories
- page
- resolution settings
- error chain

This is intended for post-failure inspection when the status bar is too small to show the full cause.

---

## Concurrency and Responsiveness

The application uses asynchronous background work to keep the terminal interactive.

### Background Work Categories

Independent background tasks are used for:
- search requests
- thumbnail fetches
- thumbnail decode work
- preview fetches
- preview decode work
- wallpaper downloads
- wallpaper/apply command execution
- external preview launch

### UI Responsiveness Goals

The UI thread remains focused on:
- input handling
- layout calculation
- rendering
- lightweight state transitions

Potentially expensive work is moved out of the foreground path.

### Stale Result Protection

Search and preview operations are generation-tracked.

This prevents older background results from overwriting newer user state when:
- a new search starts before the old one finishes
- preview focus changes while a previous preview is still loading

### Decode Strategy

Image decode is treated as heavyweight work and not left on the main async executor path. This avoids UI stalls while turning downloaded bytes into renderable images.

---

## Error Handling and Diagnostics

### User-Facing Errors

Failures are surfaced to the status bar for:
- search errors
- preview load failures
- download failures
- wallpaper command failures

### Search Failure Diagnostics

Search failures also append a detailed debug entry to the persistent debug log.

### API Failure Reporting

Remote API failures attempt to preserve useful context, including:
- HTTP status
- response content-type
- a shortened response body snippet for non-success or JSON-parse failure cases

This is specifically important because provider-side schema or payload drift can otherwise appear as opaque parse failures.

### Invalid Filter Guardrails

The client blocks invalid zero-bit filter combinations before a request is sent.

Examples of blocked states:
- purity with no enabled value
- categories with no enabled value

This avoids pointless remote requests and unclear provider-side failures.

---

## Performance Characteristics

### Fast Paths

The browsing path is optimized around:
- disk-cached thumbnails
- in-memory decoded images
- background decode work
- page-scoped API caching

### Heavy Paths

The more expensive paths are intentionally isolated:
- full-image preview load
- full-image external open
- wallpaper download
- wallpaper apply command

### Visual Quality Tradeoff

The grid favors browsing speed over full-resolution clarity.

That means:
- grid thumbnails are lightweight and responsive
- preview/download paths are where full image fidelity lives
- larger thumbnail cells will still be bounded by thumbnail-source detail

---

## Packaging and Runtime Expectations

The application is packaged as a standalone terminal executable.

Runtime assumptions:
- a network path to Wallhaven
- a writable XDG cache directory
- a writable wallpaper destination directory
- terminal support for at least one rendering strategy
- optional API key for authenticated behavior

The package is intended to be reproducible and deployable through Nix, while runtime state remains in standard user XDG locations.

---

## Current Boundaries and Intentional Tradeoffs

The current design deliberately chooses:
- thumbnail-first browsing instead of full-image grid rendering
- external command hooks instead of desktop-specific hardcoding
- disk caching plus bounded in-memory caching
- async responsiveness over synchronous simplicity
- multi-protocol terminal rendering instead of assuming a single emulator

The main consequence of these choices is:
- browsing is fast and practical
- full-image quality is reserved for preview and download flows
- enlarged thumbnails are smoother after scaling improvements, but still limited by the thumbnail source itself

---

## Summary

`waldl` is a cached, asynchronous, protocol-aware terminal wallpaper browser with:
- XDG-native configuration
- secret-file API key support
- responsive grid browsing
- in-terminal and external preview flows
- download and apply actions
- multi-layer caching
- background task isolation
- resize-aware image protocol regeneration
- persistent debug logging for failures

Its architecture is optimized for interactive browsing in a terminal while keeping heavyweight image operations off the hot path.