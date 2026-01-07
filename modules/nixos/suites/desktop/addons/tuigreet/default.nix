{ config, namespace, lib, pkgs, ... }:
let
  cfg = config.${namespace}.suites.desktop.addons.tuigreet;
  inherit (lib) mkIf mkEnableOption;
in {
  options.${namespace}.suites.desktop.addons.tuigreet = {
    enable = mkEnableOption "Tuigreet";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = rec {
        default_session = {
          command =
            "${pkgs.tuigreet}/bin/tuigreet --remember --asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' --cmd 'uwsm start -eD Hyprland hyprland-uwsm.desktop'";
          user = "greeter";
        };
        initial_session = default_session;
      };
    };

    environment.systemPackages = with pkgs; [ tuigreet ];

    # this is a life saver.
    # literally no documentation about this anywhere.
    # might be good to write about this...
    # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen
      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    # To prevent getting stuck at shutdown
    # System-level timeout (for system services)
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
    # User-level timeout (for uwsm user services)
    systemd.user.extraConfig = ''
      DefaultTimeoutStopSec=10s
    '';

  };
}
