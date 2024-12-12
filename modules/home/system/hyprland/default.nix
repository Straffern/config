{
# Snowfall Lib provides a customized `lib` instance with access to your flake's library
# as well as the libraries available from your flake's inputs.
lib,
# An instance of `pkgs` with your overlays and packages applied is also available.
pkgs,
# You also have access to your flake's inputs.
inputs,

# Additional metadata is provided by Snowfall Lib.
namespace
, # The namespace used for your flake, defaulting to "internal" if not set.
system, # The system architecture for this host (eg. `x86_64-linux`).
target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
format, # A normalized name for the system target (eg. `iso`).
virtual
, # A boolean to determine whether this system is a virtual target using nixos-generators.
systems, # An attribute map of your defined hosts.

# All other arguments come from the module system.
config, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.desktop.hyprland;
in {
  options.${namespace}.desktop.hyprland = {
    enable = mkEnableOption "Hyprland";
  };

  config = mkIf cfg.enable {
    imports = [ ./animations.nix ./bindings.nix ./polkitagent.nix ];
    # apps.kitty = enabled;

    home.packages = with pkgs; [
      qt5.qtwayland
      qt6.qtwayland
      libsForQt5.qt5ct
      qt6ct
      wayland-utils
      wayland-protocols
      wl-clipboard

      grim
      slurp
      swappy
      imagemagick
      playerctl

      (writeShellScriptBin "screenshot" ''
        grim -g "$(slurp)" - | convert - -shave 1x1 PNG:- | wl-copy
      '')
      (writeShellScriptBin "screenshot-edit" ''
        wl-paste | swappy -f -
      '')

      pulseaudio

      hyprpanel
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland = enabled;
      systemd = enabled;

      settings = {
        "$mainMod" = "SUPER";

        exec-once = [
          "xwaylandvideobridge"
          "exec ~/.config/hypr/switch_display"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        ];

        monitor = [ ",preferred,auto,1" ];

        env = [
          "XDG_SESSION_TYPE,wayland"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "MOZ_ENABLE_WAYLAND,1"
          "ANKI_WAYLAND,1"
          "DISABLE_QT5_COMPAT,0"
          "NIXOS_OZONE_WL,1" # INFO: This might be problematic on other linux systems
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "QT_AUTO_SCREEN_SCALE_FACTOR,1"
          "QT_QPA_PLATFORM=wayland,xcb"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "GTK_THEME,FlatColor:dark"
          #"GTK2_RC_FILES,/home/hadi/.local/share/themes/FlatColor/gtk-2.0/gtkrc"
          "__GL_GSYNC_ALLOWED,0"
          "__GL_VRR_ALLOWED,0"
          "DISABLE_QT5_COMPAT,0"
          "DIRENV_LOG_FORMAT,"
          "WLR_DRM_NO_ATOMIC,1"
          "WLR_BACKEND,vulkan"
          "WLR_RENDERER,vulkan"
          "WLR_NO_HARDWARE_CURSORS,1"
          "XDG_SESSION_TYPE,wayland"
          "SDL_VIDEODRIVER,wayland"
          "CLUTTER_BACKEND,wayland"
          #"AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1" # CHANGEME: Related to the GPU
        ];

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad = { natural_scroll = true; };
          sensitivity = 0.5;
        };

        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 3;
          layout = "dwindle";
        };

        decoration = { rounding = 10; };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master.new_status = "master";

        gestures.workspace_swipe = true;

        windowrulev2 = [
          "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
          "noanim,class:^(xwaylandvideobridge)$"
          "noinitialfocus,class:^(xwaylandvideobridge)$"
          "maxsize 1 1,class:^(xwaylandvideobridge)$"
          "noblur,class:^(xwaylandvideobridge)$"
        ];
      };
    };
    # wayland.windowManager.hyprland.systemd.variables = [ "--all" ];

    xdg.configFile."hypr/switch_display" = {
      enable = true;
      executable = true;
      source = ./switch_display;
    };
  };
}
