-- DMS user keybind overrides (edit via Control Center or dms; do not remove this header)

hl.unbind("SUPER + Return")
hl.bind("SUPER + Return", hl.dsp.exec_cmd("xdg-terminal-exec"), { description = "xdg-terminal-exec" })
hl.unbind("SUPER + T")
