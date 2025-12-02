{ config, lib, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.kdeconnect;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
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

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".config/kdeconnect" ];
    };
  };
}
