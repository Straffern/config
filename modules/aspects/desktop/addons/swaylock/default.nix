{den, ...}: {
  den.aspects.desktop.addons.swaylock = {
    homeManager = {
      lib,
      osConfig,
      pkgs,
      ...
    }: let
      hyprlandPackage = lib.attrByPath ["programs" "hyprland" "package"] null osConfig;
    in {
      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          show-failed-attempts = true;
          screenshots = true;
          clock = true;

          indicator = true;
          indicator-radius = 350;
          indicator-thickness = 5;

          effect-blur = "7x5";
          effect-vignette = "0.5:0.5";
          fade-in = 0.2;

          font = "MonoLisa Nerd Font";
        };
      };

      services.swayidle = {
        enable = true;
        systemdTarget = "graphical-session.target";
        events = [
          {
            event = "before-sleep";
            command = "${pkgs.swaylock-effects}/bin/swaylock -fF";
          }
          {
            event = "lock";
            command = "${pkgs.swaylock-effects}/bin/swaylock -fF";
          }
        ];
        timeouts =
          lib.optional (hyprlandPackage != null) {
            timeout = 600;
            command = "${hyprlandPackage}/bin/hyprctl dispatch dpms off";
            resumeCommand = "${hyprlandPackage}/bin/hyprctl dispatch dpms on";
          }
          ++ [
            {
              timeout = 610;
              command = "${pkgs.systemd}/bin/loginctl lock-session";
            }
          ];
      };
    };
  };
}
