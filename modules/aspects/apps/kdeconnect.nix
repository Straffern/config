{den, ...}: {
  den.aspects.apps.kdeconnect.homeManager = {
    config,
    lib,
    ...
  }: {
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
    xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = "[Desktop Entry]\nHidden=true\n";
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
    home.persistence."/persist".directories = [".config/kdeconnect"];
  };
}
