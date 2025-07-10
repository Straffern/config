{ inputs, pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      systemd.enable = true;
      systemd.enableXdgAutostart = true;
      xwayland.enable = true;

      # plugins = [ inputs.hyprland-plugins.packages.${pkgs.system}.hyprfocus ];
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
          gaps_in = 3;
          gaps_out = 5;
          border_size = 3;
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

        decoration = { rounding = 5; };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        gestures = { workspace_swipe = true; };

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
          "dbus-update-activation-environment --systemd --all"
          "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
          "${pkgs.kanshi}/bin/kanshi"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "${pkgs.pyprland}/bin/pypr"
          "${pkgs.clipse}/bin/clipse -listen"
          "${pkgs.solaar}/bin/solaar -w hide"
          "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
        ] ++ cfg.execOnceExtras;
      };
    };
  };
}
