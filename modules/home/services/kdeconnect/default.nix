{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.kdeconnect;
in {
  options.${namespace}.services.kdeconnect = {
    enable = mkEnableOption "KDEConnect service";
  };

  config = mkIf cfg.enable {
    # Hide all .desktop, except for org.kde.kdeconnect.settings
    xdg.desktopEntries = {
      "org.kde.kdeconnect.sms" = {
        exec = "";
        name = "KDE Connect SMS";
        settings.NoDisplay = "true";
      };
      "org.kde.kdeconnect.nonplasma" = {
        exec = "";
        name = "KDE Connect Indicator";
        settings.NoDisplay = "true";
      };
      "org.kde.kdeconnect.app" = {
        exec = "";
        name = "KDE Connect";
        settings.NoDisplay = "true";
      };
    };

    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    # Survive Hyprland crash restarts: broaden restart policy and wait for new Wayland socket
    systemd.user.services.kdeconnect-indicator = {
      Unit = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Restart = lib.mkForce "on-failure";
        RestartSec = 5;
      };
    };

    ${namespace}.system.persistence.directories = [".config/kdeconnect"];
  };
}
