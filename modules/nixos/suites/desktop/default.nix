{ options, config, lib, pkgs, ... }:
with lib;
with lib.custom;
let cfg = config.suites.desktop;
in {
  options.suites.desktop = with types; {
    enable = mkBoolOpt false "Enable the desktop suite";
  };

  config = mkIf cfg.enable {
    desktop.hyprland.enable = true;
    apps.firefox.enable = true;
    # apps.discord.enable = true;

    apps.tools.gnupg.enable = true;
    # apps.pass.enable = true;

    suites.common.enable = true;

    # services.devmon.enable = true;
    # services.gvfs.enable = true;
    # services.udisks2.enable = true;

    services.gpg-agent.enable = true;
    services.flatpak.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command =
            "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
          user = "greeter";
        };
      };
    };

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
    systemd.extraConfig = "DefaultTimeoutStopSec=10s";

    systemd.tmpfiles.rules =
      [ "d '/var/cache/tuigreet' - greeter greeter - -" ];

    environment.persist.directories = [ "/var/cache/tuigreet" ];

    # services.xserver = {
    #   enable = true;
    #   displayManager.gdm.enable = true;
    # };

    # environment.persist.directories = [
    #   "/etc/gdm"
    # ];

    environment.systemPackages = with pkgs; [
      greetd.tuigreet
      nemo
      xclip
      xarchiver
    ];
  };
}
