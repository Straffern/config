{ inputs, pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption map;
  cfg = config.${namespace}.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      systemd.enable = false;
      systemd.enableXdgAutostart = false;
      xwayland.enable = true;

      # plugins = [ inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus ];
      settings = {

        ecosystem.no_update_news = true;

        input = {
          kb_layout = "us";
          touchpad = {
            disable_while_typing = false;
            natural_scroll = true;
          };

          sensitivity = 0.5; # -1.0 - 1.0, 0 means no modification.
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };

        # https://wiki.hypr.land/Configuring/Variables/#group
        group = {

          groupbar = {
            indicator_height = 0;
            indicator_gap = 5;
            height = 22;
            gaps_in = 5;
            gaps_out = 0;

            gradients = true;
            gradient_rounding = 0;
            gradient_round_only_edges = false;
          };
        };

        # animations.enabled = false;

        animations = {
          enabled = true;

          bezier = [
            "flashCurve, 0.22, 1, 0.36, 1" # This is an "easeOutQuint" curve
            "linear, 0.0, 0.0, 1.0, 1.0"
          ];

          animation = [
            # Format: name, on, speed, curve
            # "hyprfocusIn, 1, 2, flashCurve"
            # "hyprfocusOut, 1, 2, linear"

            # Format: name, on, speed, curve, style
            "windows, 0, 1, linear"
            "windowsIn, 0, 1, linear"
            "windowsOut, 0, 1, linear"
            "windowsMove, 0, 1, linear"
            "border, 0, 1, linear"
            "borderangle, 0, 1, linear"
            "fade, 0, 1, linear"
            "workspaces, 0, 1, linear"
          ];

        };

        # decoration = { rounding = 5; };

        # https://wiki.hyprland.org/Configuring/Variables/#decoration
        decoration = {
          rounding = 0;

          shadow = {
            enabled = true;
            range = 2;
            render_power = 3;
          };

          # https://wiki.hyprland.org/Configuring/Variables/#blur
          blur = {
            enabled = true;
            size = 3;
            passes = 1;

            vibrancy = 0.1696;
          };
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        gestures.gesture = [ "3, horizontal, workspace" ];

        binds.movefocus_cycles_fullscreen = true;

        misc = let FULLSCREEN_ONLY = 2;
        in {
          vrr = FULLSCREEN_ONLY;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
        };
        monitor = ", preferred, auto, 1";
        # source = [ "${config.home.homeDirectory}/.config/hypr/monitors.conf" ];

        exec-once = [
          # UWSM handles dbus-update-activation-environment and systemd target activation
          "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
          # "uwsm app -- ${pkgs.kanshi}/bin/kanshi"
          "uwsm app -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "uwsm app -- ${pkgs.pyprland}/bin/pypr"
          "uwsm app -- ${pkgs.clipse}/bin/clipse -listen"
          "uwsm app -- ${pkgs.solaar}/bin/solaar -w hide"
          "uwsm app -- ${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
        ] ++ cfg.execOnceExtras;
      };
    };
  };
}
