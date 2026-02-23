{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # New windowrule syntax (Hyprland 0.53+)
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrule = [
        "suppress_event maximize, match:class .*"

        # Just dash of opacity by default
        "opacity 0.97 0.9, match:class .*"

        # Fix some dragging issues with XWayland
        "no_focus on, match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false"

        # Float and center file pickers
        "tag +picker, match:class (xdg-desktop-portal-gtk|sublime_text)"
        "float on, match:tag picker, match:title ^(Open.*Files?|Save.*Files?|All Files|Save)"
        "center on, match:tag picker, match:title ^(Open.*Files?|Save.*Files?|All Files|Save)"
        "size 800 600, match:tag picker"

        # Terminal windows: transparent by default
        "opacity 0.9 0.8, match:class ^(kitty|kitty-dropterm)$"

        # Drop-down terminal
        "float on, match:class ^(kitty-dropterm)$"
        "move 50%-w/2 5%, match:class ^(kitty-dropterm)$"

        # No transparency on media windows
        "opacity 1 1, match:class ^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"
        "float on, match:class ^(imv)$"
        "center on, match:class ^(imv)$"
        "size 1200 800, match:class ^(imv)$"

        # Volume Control
        "float on, match:class ^(org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
        "center on, match:class ^(org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
        "size 50% 60%, match:class ^(org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"

        # Bluetooth Manager
        "float on, match:class ^(.blueman-manager-wrapped)$"
        "center on, match:class ^(.blueman-manager-wrapped)$"
        "size 800 600, match:class ^(.blueman-manager-wrapped)$"

        # Trayscale
        "float on, match:class ^(dev.deedles.Trayscale)$"
        "center on, match:class ^(dev.deedles.Trayscale)$"
        "size 800 600, match:class ^(dev.deedles.Trayscale)$"

        # Picture-in-picture overlays
        "tag +pip, match:title (Picture.?in.?[Pp]icture)"
        "float on, match:tag pip"
        "pin on, match:tag pip"
        "size 600 338, match:tag pip"
        "keep_aspect_ratio on, match:tag pip"
        "decorate false, match:tag pip"
        "opacity 1 1, match:tag pip"
        "move 100%-w-40 4%, match:tag pip"

        # Force chromium and brave into a tile to deal with --app bug
        "tile on, match:class ^(Chromium|brave-browser)$"

        # Only slight opacity when unfocused
        "opacity 1 0.97, match:class ^(Chromium|chromium|google-chrome|google-chrome-unstable|brave-browser)$"
        "opacity 1 1, match:initial_title ^(youtube.com_/)$"

        "idle_inhibit fullscreen, match:class ^(firefox)$"
        "idle_inhibit fullscreen, match:class ^(brave-browser)$"
      ];
    };
  };
}
