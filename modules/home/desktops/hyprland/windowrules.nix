{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        "suppressevent maximize, class:.*"

        # Just dash of opacity by default
        "opacity 0.97 0.9, class:.*"

        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

        # Float and center file pickers
        "tag +picker, class:(xdg-desktop-portal-gtk|sublime_text)"
        "float, tag:picker, title:^(Open.*Files?|Save.*Files?|All Files|Save)"
        "center, tag:picker, title:^(Open.*Files?|Save.*Files?|All Files|Save)"
        "size 800 600, tag:picker"

        # No transparency on media windows
        "opacity 1 1, class:^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"

        # Pipewire Volume Control
        "float, class:^(com.saivert.pwvucontrol)$"
        "center, class:^(com.saivert.pwvucontrol)$"
        "size 800 600, class:^(com.saivert.pwvucontrol)$"

        # Picture-in-picture overlays
        "tag +pip, title:(Picture.{0,1}in.{0,1}[Pp]icture)"
        "float, tag:pip"
        "pin, tag:pip"
        "size 600 338, tag:pip"
        "keepaspectratio, tag:pip"
        "noborder, tag:pip"
        "opacity 1 1, tag:pip"
        "move 100%-w-40 4%, tag:pip"

        # Force chromium and brave into a tile to deal with --app bug
        "tile, class:^(Chromium|brave-browser)$"

        # Only slight opacity when unfocused
        "opacity 1 0.97, class:^(Chromium|chromium|google-chrome|google-chrome-unstable|brave-browser)$"
        "opacity 1 1, initialTitle:^(youtube.com_/)$" # Youtube
      ];

      windowrulev2 = [
        "idleinhibit fullscreen, class:^(firefox)$"
        "idleinhibit fullscreen, class:^(brave)$"
        # "float, title:^(Picture in picture)$"
        # "pin, title:^(Picture in picture)$"
      ];

    };
  };
}
