# Patch hyprtoolkit to gracefully handle display disconnection (monitor unplug)
# instead of crashing with RASSERT.
#
# Bug: https://github.com/hyprwm/hyprtoolkit/issues/37
# Remove this overlay once upstream fixes the issue.
_: _final: prev: {
  hyprtoolkit = prev.hyprtoolkit.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        # Replace RASSERT crash with graceful termination on display disconnect
        substituteInPlace src/core/Backend.cpp \
          --replace-fail \
            'RASSERT(!(m_pollfds[i].revents & POLLHUP), "[core] Disconnected from pollfd id {}", i);' \
            'if (m_pollfds[i].revents & POLLHUP) { g_logger->log(HT_LOG_WARNING, "[core] Disconnected from pollfd id {}, terminating gracefully", i); wl_display_cancel_read(g_waylandPlatform->m_waylandState.display); m_terminate = true; return; }'
      '';
  });
}
