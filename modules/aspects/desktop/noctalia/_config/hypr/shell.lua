-- Noctalia shell integration for Hyprland, loaded by hyprland.lua.

local function noctalia(args)
	return hl.dsp.exec_cmd("noctalia msg " .. args)
end

-- Colors: Noctalia renders hypr/noctalia.lua; absent until its first palette render.
local themed, theme = pcall(require, "noctalia")
if themed then
	theme.apply_theme()
end

hl.monitor({ output = "desc:BOE NE135A1M-NY1", mode = "2880x1920@120.000", position = "0x0", scale = 1.6, vrr = 1 })

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		resize_on_border = false,
	},
	decoration = {
		rounding = 12,
		rounding_power = 2,
	},
})

hl.env("HYPRCURSOR_THEME", "phinger-cursors-dark")
hl.env("XCURSOR_THEME", "phinger-cursors-dark")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")

hl.window_rule({ match = { class = "^dev\\.noctalia\\.Noctalia$" }, float = true, size = { 1080, 920 } })
hl.window_rule({ match = { class = "^footclient$" }, opacity = 0.84 })
hl.layer_rule({
	name = "noctalia",
	match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
	no_anim = true,
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})

-- === Shell ===
hl.bind("SUPER + Return", hl.dsp.exec_cmd("xdg-terminal-exec"), { description = "Open terminal" })
hl.bind("SUPER + space", noctalia("panel-toggle launcher"), { description = "Application launcher" })
hl.bind("SUPER + V", noctalia("panel-toggle clipboard"), { description = "Clipboard history" })
hl.bind("SUPER + M", noctalia("panel-toggle control-center system"), { description = "System monitor" })
hl.bind("SUPER + comma", noctalia("settings-toggle"), { description = "Settings" })
hl.bind("SUPER + N", noctalia("panel-toggle control-center notifications"), { description = "Notification center" })
hl.bind("SUPER + Y", noctalia("panel-toggle wallpaper"), { description = "Browse wallpapers" })
hl.bind("SUPER + X", noctalia("panel-toggle session"), { description = "Session menu" })
hl.bind("ALT + TAB", noctalia("window-switcher hold"), { description = "Window switcher" })
hl.bind("SUPER + TAB", noctalia("window-switcher"), { description = "Window switcher" })

-- === Security ===
hl.bind("SUPER + BackSpace", noctalia("session lock"), { description = "Lock screen" })
hl.bind("SUPER + ALT + L", noctalia("session lock"), { description = "Lock screen" })
hl.bind("SUPER + ALT + I", noctalia("caffeine-toggle"), { description = "Toggle idle inhibit (no lock or suspend)" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

-- === Audio and brightness ===
hl.bind("XF86AudioRaiseVolume", noctalia("volume-up 3"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", noctalia("volume-down 3"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", noctalia("volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", noctalia("mic-mute"), { locked = true })
hl.bind("XF86AudioPause", noctalia("media toggle"), { locked = true })
hl.bind("XF86AudioPlay", noctalia("media toggle"), { locked = true })
hl.bind("XF86AudioPrev", noctalia("media previous"), { locked = true })
hl.bind("XF86AudioNext", noctalia("media next"), { locked = true })
hl.bind("XF86MonBrightnessUp", noctalia("brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", noctalia("brightness-down"), { locked = true, repeating = true })

-- === Screenshots ===
hl.bind("Print", noctalia("screenshot-region"))
hl.bind("CTRL + Print", noctalia("screenshot-fullscreen"))

-- === Window management ===
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + bracketleft", hl.dsp.layout("preselect l"))
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"))
hl.bind("SUPER + SHIFT + P", hl.dsp.dpms({ action = "toggle" }))

local directions = { left = "l", down = "d", up = "u", right = "r", H = "l", J = "d", K = "u", L = "r" }
for key, direction in pairs(directions) do
	hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
	hl.bind("SUPER + CTRL + " .. key, hl.dsp.focus({ monitor = direction }))
	hl.bind("SUPER + SHIFT + CTRL + " .. key, hl.dsp.window.move({ monitor = direction }))
end
hl.bind("SUPER + Home", hl.dsp.focus({ window = "first" }))
hl.bind("SUPER + End", hl.dsp.focus({ window = "last" }))

-- === Workspaces ===
for i = 1, 9 do
	hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
	hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
for _, step in ipairs({ { "Page_Down", "U", "mouse_down", "e+1" }, { "Page_Up", "I", "mouse_up", "e-1" } }) do
	local page, letter, wheel, workspace = step[1], step[2], step[3], step[4]
	hl.bind("SUPER + " .. page, hl.dsp.focus({ workspace = workspace }))
	hl.bind("SUPER + " .. letter, hl.dsp.focus({ workspace = workspace }))
	hl.bind("SUPER + " .. wheel, hl.dsp.focus({ workspace = workspace }))
	hl.bind("SUPER + SHIFT + " .. page, hl.dsp.window.move({ workspace = workspace }))
	hl.bind("SUPER + SHIFT + " .. letter, hl.dsp.window.move({ workspace = workspace }))
	hl.bind("SUPER + CTRL + " .. letter, hl.dsp.window.move({ workspace = workspace }))
	hl.bind("SUPER + CTRL + " .. wheel, hl.dsp.window.move({ workspace = workspace }))
end
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- === Sizing ===
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
