//! Full-size wallpaper preview rendering.

use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph};
use ratatui_image::{FilterType, Resize, StatefulImage};

use crate::app::App;

/// Renders the full-size preview of the currently selected wallpaper.
pub fn draw_preview(frame: &mut Frame, app: &mut App, area: Rect) {
    let Some(item) = app.grid.get(app.preview_index) else {
        let msg =
            Paragraph::new("No wallpaper selected").style(Style::default().fg(Color::DarkGray));
        frame.render_widget(msg, area);
        return;
    };

    // Layout: image (fill) | info bar (2 rows)
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(2)])
        .split(area);

    // Image area
    let wp = &item.wallpaper;
    let title = format!(
        " {} — {}  {}x{} ",
        wp.id, wp.category, wp.dimension_x, wp.dimension_y
    );
    let block = Block::default()
        .title(title)
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::Cyan));

    let inner = block.inner(chunks[0]);
    frame.render_widget(block, chunks[0]);

    if let Some(ref mut protocol) = app.preview_protocol {
        let image = StatefulImage::default().resize(Resize::Scale(Some(FilterType::CatmullRom)));
        frame.render_stateful_widget(image, inner, protocol);
    } else if app.preview_loading {
        let loading = Paragraph::new(Line::from(Span::styled(
            "Loading full image...",
            Style::default().fg(Color::Yellow),
        )));
        frame.render_widget(loading, inner);
    }

    // Info bar
    let info = Line::from(vec![
        Span::styled(" Space/Esc", Style::default().fg(Color::Cyan)),
        Span::raw(" back \u{2502} "),
        Span::styled("h/l", Style::default().fg(Color::Cyan)),
        Span::raw(" prev/next \u{2502} "),
        Span::styled("m", Style::default().fg(Color::Cyan)),
        Span::raw(if item.marked { " unmark" } else { " mark" }),
        Span::raw(" \u{2502} "),
        Span::styled("d", Style::default().fg(Color::Cyan)),
        Span::raw(" download \u{2502} "),
        Span::styled("w", Style::default().fg(Color::Cyan)),
        Span::raw(" set wallpaper \u{2502} "),
        Span::styled("o", Style::default().fg(Color::Cyan)),
        Span::raw(" open external"),
        Span::raw("  \u{2502}  "),
        Span::styled(
            format!("{}/{} ", app.preview_index + 1, app.grid.len()),
            Style::default()
                .fg(Color::DarkGray)
                .add_modifier(Modifier::ITALIC),
        ),
    ]);
    let info_widget = Paragraph::new(info);
    frame.render_widget(info_widget, chunks[1]);
}
