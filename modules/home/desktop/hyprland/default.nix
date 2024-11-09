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
with lib.custom;
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktop.hyprland;
in {
  options.${namespace}.desktop.hyprland = {
    enable = mkEnableOption "Hyprland";
  };

  config = mkIf cfg.enable {

    apps.kitty = enabled;

    home.packages = with pkgs; [
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

    wayland.windowManager.hyprland.enabled = true;

    wayland.windowManager.hyprland.systemd.variables = [ "--all" ];

    wayland.windowManager.hyprland.settings = {
      monitor = [ ",preferred,auto,1" ];

      exec-once = [ "xwaylandvideobridge" "ags" ];

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

      decoration = {
        rounding = 10;
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      animations = {
        enabled = true;
        bezier = [ "overshot,0.13,0.99,0.29,1.1" "linear,0.0,0.0,1.0,1.0" ];
        animation = [
          "windows,1,4,overshot,slide"
          "fade,1,10,default"
          "workspaces,1,6,overshot,slide"
          "borderangle,1,100,linear,loop"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master.new_status = "master";

      gestures.workspace_swipe = true;

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, RETURN, exec, foot"
        "$mainMod, Q, killactive,"
        "$mainMod, SPACE, togglefloating,"
        "$mainMod, P, exec, wofi --show drun"
        "$mainMod, F, fullscreen"
        "$mainMod, TAB, pseudo"
        "$mainMod_SHIFT, E, exec, wlogout -b 1 -p layer-shell"
        "$mainMod_SHIFT, Q, exec, gtklock"
        "$mainMod_SHIFT, C, exec, wallpaper"
        ", code:107, exec, screenshot"
        "$mainMod, code:107, exec, screenshot-edit"
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"
        "$mainMod_SHIFT, h, movewindow, l"
        "$mainMod_SHIFT, l, movewindow, r"
        "$mainMod_SHIFT, k, movewindow, u"
        "$mainMod_SHIFT, j, movewindow, d"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioStop, exec, playerctl stop"
      ];

      bindl = [ ", code:127, exec, wpctl set-volume @DEFAULT_SOURCE@ 100%" ];

      bindrl = [ ", code:127, exec, wpctl set-volume @DEFAULT_SOURCE@ 0%" ];

      binde = [
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrulev2 = [
        "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"
      ];
    };

  };
}
