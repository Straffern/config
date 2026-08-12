{den, ...}: {
  den.aspects.desktop.tuigreet.nixos = {pkgs, ...}: {
    services.greetd = {
      enable = true;
      settings = rec {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --remember --asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' --cmd 'uwsm start -F -eD Hyprland -- start-hyprland'";
          user = "greeter";
        };
        initial_session = default_session;
      };
    };
    environment.systemPackages = [pkgs.tuigreet];
    systemd = {
      services.greetd.serviceConfig = {
        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "journal";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };
      settings.Manager.DefaultTimeoutStopSec = "10s";
      user.extraConfig = "DefaultTimeoutStopSec=10s";
    };
  };
}
