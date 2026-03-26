//! TUI rendering — layout orchestration and submodule re-exports.

pub mod filters;
pub mod grid;
pub mod preview;
pub mod status;

use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Clear, Paragraph, Wrap};

use crate::app::{App, Mode};

/// Main draw entry point — called every frame.
pub fn draw(frame: &mut Frame, app: &mut App) {
    let area = frame.area();

    // Layout: header (2 rows) | body (fill) | status (1 row)
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2), // header
            Constraint::Min(0),    // body
            Constraint::Length(1), // status bar
        ])
        .split(area);

    draw_header(frame, app, chunks[0]);

    match app.mode {
        Mode::Grid => grid::draw_grid(frame, app, chunks[1]),
        Mode::Preview => preview::draw_preview(frame, app, chunks[1]),
        Mode::Search => {
            grid::draw_grid(frame, app, chunks[1]);
            draw_search_input(frame, app, area);
        }
        Mode::Help => {
            grid::draw_grid(frame, app, chunks[1]);
            draw_help_overlay(frame, chunks[1]);
        }
    }

    status::draw_status(frame, app, chunks[2]);
}

fn draw_header(frame: &mut Frame, app: &App, area: Rect) {
    let query_display = if app.params.query.is_empty() {
        "browse".to_string()
    } else {
        app.params.query.clone()
    };

    let purity_display = format_purity(&app.params.purity);
    let category_display = format_categories(&app.params.categories);

    let res_display = app.resolution_display();

    let mut spans = vec![
        Span::styled(" waldl ", Style::default().fg(Color::Black).bg(Color::Cyan)),
        Span::raw("  "),
        Span::styled("Q:", Style::default().fg(Color::DarkGray)),
        Span::styled(
            format!(" {query_display} "),
            Style::default()
                .fg(Color::White)
                .add_modifier(Modifier::BOLD),
        ),
        Span::raw(" \u{2502} "),
        Span::styled(
            purity_display.to_string(),
            Style::default().fg(Color::Yellow),
        ),
        Span::raw(" \u{2502} "),
        Span::styled(
            category_display.to_string(),
            Style::default().fg(Color::Green),
        ),
        Span::raw(" \u{2502} "),
        Span::styled(
            format!("{}", app.params.sorting),
            Style::default().fg(Color::Magenta),
        ),
    ];

    if app.params.sorting == crate::api::Sorting::Toplist {
        spans.push(Span::styled(
            format!(" ({})", app.params.toplist_range),
            Style::default().fg(Color::DarkGray),
        ));
    }

    if !res_display.is_empty() {
        spans.push(Span::raw(" \u{2502} "));
        spans.push(Span::styled(res_display, Style::default().fg(Color::Blue)));
    }

    let header_text = Line::from(spans);

    let block = Block::default()
        .borders(Borders::BOTTOM)
        .border_style(Style::default().fg(Color::DarkGray));

    let header = Paragraph::new(header_text).block(block);
    frame.render_widget(header, area);
}

fn draw_search_input(frame: &mut Frame, app: &App, area: Rect) {
    // Centered input box
    let width = area.width.min(60);
    let x = (area.width.saturating_sub(width)) / 2;
    let y = area.height / 3;
    let input_area = Rect::new(x, y, width, 3);

    frame.render_widget(Clear, input_area);

    let block = Block::default()
        .title(" Search (Enter=submit, Esc=cancel) ")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::Cyan));

    let input = Paragraph::new(app.search_input.as_str())
        .block(block)
        .style(Style::default().fg(Color::White));

    frame.render_widget(input, input_area);

    // Place cursor
    let cursor_x = input_area.x + 1 + app.search_cursor as u16;
    let cursor_y = input_area.y + 1;
    frame.set_cursor_position((cursor_x, cursor_y));
}

fn draw_help_overlay(frame: &mut Frame, area: Rect) {
    let width = area.width.min(50);
    let height = area.height.min(26);
    let x = (area.width.saturating_sub(width)) / 2;
    let y = (area.height.saturating_sub(height)) / 2;
    let help_area = Rect::new(x, y, width, height);

    frame.render_widget(Clear, help_area);

    let help_text = vec![
        Line::from(Span::styled(
            " Keybindings ",
            Style::default()
                .fg(Color::Black)
                .bg(Color::Cyan)
                .add_modifier(Modifier::BOLD),
        )),
        Line::from(""),
        Line::from(" Navigation"),
        Line::from("  h/j/k/l, arrows  Move selection"),
        Line::from("  Space / p        In-terminal preview"),
        Line::from("  o                Open external viewer"),
        Line::from("  Enter            Search / re-search"),
        Line::from("  n / PageDown     Next page"),
        Line::from("  N / PageUp       Prev page"),
        Line::from(""),
        Line::from(" Actions"),
        Line::from("  m                Mark for download"),
        Line::from("  d                Download marked"),
        Line::from("  w                Set wallpaper"),
        Line::from("  /                Search input"),
        Line::from(""),
        Line::from(" Filters"),
        Line::from("  s                Cycle sorting"),
        Line::from("  1/2/3            Toggle SFW/Sketchy/NSFW"),
        Line::from("  4/5/6            Toggle General/Anime/People"),
        Line::from("  a                Cycle min resolution"),
        Line::from("  r                Cycle aspect ratio"),
        Line::from("  t                Cycle toplist range"),
        Line::from(""),
        Line::from("  q/Esc            Quit  |  ?  This help"),
    ];

    let block = Block::default()
        .title(" Help ")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::Cyan));

    let help = Paragraph::new(help_text)
        .block(block)
        .wrap(Wrap { trim: false });

    frame.render_widget(help, help_area);
}

fn format_purity(purity: &str) -> String {
    let chars: Vec<char> = purity.chars().collect();
    let labels = [("S", "SFW"), ("K", "Sketchy"), ("N", "NSFW")];
    let mut parts = Vec::new();
    for (i, (short, _)) in labels.iter().enumerate() {
        if chars.get(i) == Some(&'1') {
            parts.push(*short);
        }
    }
    if parts.is_empty() {
        "none".into()
    } else {
        parts.join("+")
    }
}

fn format_categories(cats: &str) -> String {
    let chars: Vec<char> = cats.chars().collect();
    let labels = ["Gen", "Ani", "Ppl"];
    let mut parts = Vec::new();
    for (i, label) in labels.iter().enumerate() {
        if chars.get(i) == Some(&'1') {
            parts.push(*label);
        }
    }
    if parts.is_empty() {
        "none".into()
    } else {
        parts.join("+")
    }
}
