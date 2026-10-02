hl.layer_rule({ match = { namespace = "^(quickshell)$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^dms:.*" }, no_anim = true })

require("dms.colors")
require("dms.outputs")
require("dms.layout")
require("dms.cursor")
require("dms.binds")
require("dms.binds-user")
require("dms.windowrules")

hl.bind("SUPER + BackSpace", hl.dsp.exec_cmd("dms ipc call lock lock"), { description = "Lock screen" })
hl.bind("SUPER + ALT + I", hl.dsp.exec_cmd("dms ipc call inhibit toggle"), { description = "Toggle idle inhibit (no lock or suspend)" })
