//! Thumbnail grid widget — renders wallpaper thumbnails in a responsive grid.

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph};
use ratatui_image::{FilterType, Resize, StatefulImage};

use crate::app::App;

/// Renders the thumbnail grid within the given area.
pub fn draw_grid(frame: &mut Frame, app: &mut App, area: Rect) {
    if app.grid.is_empty() {
        draw_empty(frame, app, area);
        return;
    }

    let layout = app.compute_grid_layout(area.width, area.height);
    let cols = layout.cols;
    let cell_w = layout.cell_w;
    let cell_h = layout.cell_h;
    let visible_rows = layout.visible_rows;

    // Update app's knowledge of grid cols for navigation
    app.last_grid_cols = cols;

    // Ensure selected is in view by adjusting scroll
    let selected_row = app.selected / cols;
    if selected_row < app.scroll_row {
        app.scroll_row = selected_row;
    }
    if selected_row >= app.scroll_row + visible_rows {
        app.scroll_row = selected_row - visible_rows + 1;
    }

    // Render visible cells
    for vis_row in 0..visible_rows {
        let data_row = app.scroll_row + vis_row;
        for col in 0..cols {
            let idx = data_row * cols + col;
            if idx >= app.grid.len() {
                break;
            }

            let x = area.x + col as u16 * cell_w;
            let y = area.y + vis_row as u16 * cell_h;

            // Clip to available area
            let w = cell_w.min(area.x + area.width - x);
            let h = cell_h.min(area.y + area.height - y);
            if w < 3 || h < 3 {
                continue;
            }

            let cell_area = Rect::new(x, y, w, h);
            draw_grid_cell(frame, app, idx, cell_area);
        }
    }
}

fn draw_grid_cell(frame: &mut Frame, app: &mut App, index: usize, area: Rect) {
    let is_selected = index == app.selected;
    let item = &app.grid[index];
    let is_marked = item.marked;

    // Border style based on selection / marking
    let border_style = if is_selected && is_marked {
        Style::default()
            .fg(Color::Green)
            .add_modifier(Modifier::BOLD)
    } else if is_selected {
        Style::default()
            .fg(Color::Cyan)
            .add_modifier(Modifier::BOLD)
    } else if is_marked {
        Style::default().fg(Color::Green)
    } else {
        Style::default().fg(Color::DarkGray)
    };

    // Title: wallpaper id + resolution
    let id = &item.wallpaper.id;
    let res = &item.wallpaper.resolution;
    let title = if is_marked {
        format!(" ✓ {id} ({res}) ")
    } else {
        format!(" {id} ({res}) ")
    };

    let block = Block::default()
        .title(title)
        .borders(Borders::ALL)
        .border_style(border_style);

    let inner = block.inner(area);
    frame.render_widget(block, area);

    // Render image or placeholder
    if inner.width > 0 && inner.height > 0 {
        if let Some(ref mut protocol) = app.grid[index].protocol {
            let image =
                StatefulImage::default().resize(Resize::Scale(Some(FilterType::CatmullRom)));
            frame.render_stateful_widget(image, inner, protocol);
        } else {
            // Loading placeholder
            let placeholder = Paragraph::new(Line::from(Span::styled(
                "loading...",
                Style::default().fg(Color::DarkGray),
            )));
            frame.render_widget(placeholder, inner);
        }
    }
}

fn draw_empty(frame: &mut Frame, app: &App, area: Rect) {
    let msg = if app.loading {
        "Searching..."
    } else {
        "Press / to search or Enter to browse latest wallpapers"
    };

    let text = Paragraph::new(Line::from(Span::styled(
        msg,
        Style::default().fg(Color::DarkGray),
    )));
    frame.render_widget(text, area);
}
