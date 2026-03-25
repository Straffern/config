{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.services.kdeconnect;
in {
  options.${namespace}.services.kdeconnect = {
    enable = mkEnableOption "KDEConnect service";
    indicator = mkOption {
      type = types.bool;
      default = true;
      description = "Show KDE Connect tray indicator. Disable when the desktop shell provides its own notification integration.";
    };
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
      inherit (cfg) indicator;
    };

    # Suppress duplicate XDG autostart: daemon is already managed by kdeconnect.service
    xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';

    # Survive crash restarts: broaden restart policy
    systemd.user.services.kdeconnect = {
      Unit = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Restart = lib.mkForce "on-failure";
        RestartSec = 5;
      };
    };
    systemd.user.services.kdeconnect-indicator = mkIf cfg.indicator {
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
