{den, ...}: {
  den.aspects.desktop.addons.kanshi = {
    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [kanshi];

      services.kanshi = {
        enable = true;
        package = pkgs.kanshi;
        systemdTarget = "graphical-session.target";
        settings = [
          {
            profile = {
              name = "undocked";
              outputs = [
                {
                  criteria = "eDP-1";
                  status = "enable";
                  position = "0,0";
                }
              ];
            };
          }
          {
            profile = {
              name = "home_office_laptop_docked";
              outputs = [
                {
                  criteria = "Samsung Electric Company U32R59x H4ZN200523";
                  position = "0,0";
                  mode = "3840x2160@60.00Hz";
                }
                {
                  criteria = "eDP-1";
                  status = "disable";
                }
              ];
            };
          }
        ];
      };

      systemd.user.services.kanshi = {
        Unit = {
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          RestartSec = 5;
        };
      };
    };
  };
}
