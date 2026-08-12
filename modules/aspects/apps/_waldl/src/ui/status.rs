//! Status bar at the bottom of the TUI.

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;

use crate::app::App;

pub fn draw_status(frame: &mut Frame, app: &App, area: Rect) {
    let page_info = if app.last_page() > 1 {
        format!(
            " pg {}/{} ({} total) ",
            app.current_page(),
            app.last_page(),
            app.total_results()
        )
    } else {
        String::new()
    };

    let marked_count = app.grid.iter().filter(|g| g.marked).count();
    let marked_info = if marked_count > 0 {
        format!(" │ {marked_count} marked")
    } else {
        String::new()
    };

    let line = Line::from(vec![
        Span::styled(
            format!(" {} ", app.status),
            if app.loading {
                Style::default().fg(Color::Yellow)
            } else {
                Style::default().fg(Color::White)
            },
        ),
        Span::styled(page_info, Style::default().fg(Color::Cyan)),
        Span::styled(
            marked_info,
            Style::default()
                .fg(Color::Green)
                .add_modifier(Modifier::BOLD),
        ),
        // Right-aligned help hint
        Span::styled(" ? help ", Style::default().fg(Color::DarkGray)),
    ]);

    let status = Paragraph::new(line).style(Style::default().bg(Color::DarkGray).fg(Color::White));
    frame.render_widget(status, area);
}
