{den, ...}: {
  den.aspects.apps.kdeconnect.homeManager = {
    config,
    lib,
    host,
    ...
  }: let
    dmsEnabled = config.programs.dank-material-shell.enable or false;
  in
    lib.mkMerge [
      {
        home.packages = [config.services.kdeconnect.package];
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
        services.kdeconnect = lib.mkIf (!dmsEnabled) {
          enable = true;
          indicator = true;
        };
        xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop" = lib.mkIf (!dmsEnabled) {
          text = "[Desktop Entry]\nHidden=true\n";
        };
        systemd.user.services.kdeconnect = lib.mkIf (!dmsEnabled) {
          Unit = {
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
          };
          Service = {
            Restart = lib.mkForce "on-failure";
            RestartSec = 5;
          };
        };
        systemd.user.services.kdeconnect-indicator = lib.mkIf (!dmsEnabled) {
          Unit = {
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
          };
          Service = {
            Restart = lib.mkForce "on-failure";
            RestartSec = 5;
          };
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".config/kdeconnect"];
      })
    ];
}
