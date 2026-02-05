{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktops.hyprland;

  # Trayscale doesn't respond to SIGTERM, needs D-Bus quit action for graceful shutdown
  trayscaleWithGracefulShutdown = ''
    uwsm app -t service \
      -p TimeoutStopSec=5 \
      -p 'Restart=on-failure' \
      -p 'RestartSec=5' \
      -p 'ExecStop=${pkgs.systemdMinimal}/bin/busctl --user call dev.deedles.Trayscale /dev/deedles/Trayscale org.gtk.Actions Activate sava{sv} quit 0 0' \
      -- ${pkgs.trayscale}/bin/trayscale --hide-window
  '';
in {
  config = mkIf cfg.enable {
    # Suppress duplicate XDG autostart: blueman-applet is already launched via uwsm exec-once
    xdg.configFile."autostart/blueman.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';

    home.packages = [pkgs.hyprpicker];
    wayland.windowManager.hyprland = {
      enable = true;

      systemd.enable = false;
      systemd.enableXdgAutostart = false;
      xwayland.enable = true;

      # plugins = [ inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus ];
      settings = {
        ecosystem.no_update_news = true;

        input = {
          # Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
          kb_layout = "us,dk";
          kb_options = "grp:alts_toggle, # compose:caps";
          touchpad = {
            # disable_while_typing = false;
            natural_scroll = true;

            # Use two-finger clicks for right-click instead of lower-right corner
            clickfinger_behavior = true;

            # Control the speed of your scrolling
            # scroll_factor = 0.4

            # Left-click-and-drag with three fingers
            # drag_3fg = 1;
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

        gesture = ["3, horizontal, workspace"];

        binds.movefocus_cycles_fullscreen = true;

        misc = let
          FULLSCREEN_ONLY = 2;
        in {
          vrr = FULLSCREEN_ONLY;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
        };

        monitor = ", preferred, auto, 1";
        # source = [ "${config.home.homeDirectory}/.config/hypr/monitors.conf" ];

        env = [
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "QT_QPA_PLATFORM,wayland;xcb"
        ];

        exec-once =
          [
            "uwsm finalize"
            # UWSM handles dbus-update-activation-environment and systemd target activation
            "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
            "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
            # Services with restart resilience for Hyprland crash recovery
            "uwsm app -t service -p 'Restart=on-failure' -p 'RestartSec=5' -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            "uwsm app -t service -p 'Restart=on-failure' -p 'RestartSec=5' -- ${pkgs.clipse}/bin/clipse -listen"
            "uwsm app -t service -p 'Restart=on-failure' -p 'RestartSec=5' -- ${pkgs.solaar}/bin/solaar -w hide"
            "uwsm app -t service -p 'Restart=on-failure' -p 'RestartSec=5' -- ${pkgs.networkmanagerapplet}/bin/nm-applet"
            "uwsm app -t service -p 'Restart=on-failure' -p 'RestartSec=5' -- ${pkgs.blueman}/bin/blueman-applet"
            trayscaleWithGracefulShutdown
            # kdeconnect-indicator managed by services.kdeconnect.indicator (HM systemd service)
            # pyprland managed via systemd.user.services.pyprland
          ]
          ++ cfg.execOnceExtras;
      };
    };
  };
}
