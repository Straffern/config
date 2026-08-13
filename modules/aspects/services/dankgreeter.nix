{den, ...}: {
  den.aspects.services.dankgreeter.nixos = {
    config,
    inputs',
    lib,
    pkgs,
    ...
  }: {
    systemd.tmpfiles.rules = [
      "d /var/lib/dms-greeter/.local 0750 dms-greeter dms-greeter -"
      "d /var/lib/dms-greeter/.local/state 0750 dms-greeter dms-greeter -"
      "d /var/lib/dms-greeter/.local/state/wireplumber 0750 dms-greeter dms-greeter -"
    ];
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
      package = inputs'.dms.packages.default;
      configHome = config.users.users.alex.home;
    };
    services.fprintd.enable = true;
    security.pam.services.login.fprintAuth = false;
    security.pam.services = {
      greetd = {
        fprintAuth = true;
        rules.auth.fprintd.settings = {
          "max-tries" = "1";
          timeout = "5";
        };
      };
      dms-greeter = {
        fprintAuth = true;
        rules.auth.fprintd.settings = {
          "max-tries" = "1";
          timeout = "5";
        };
      };
    };
    environment.systemPackages = [pkgs.fprintd];
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
    systemd.user.extraConfig = "DefaultTimeoutStopSec=10s\n";
  };
}
