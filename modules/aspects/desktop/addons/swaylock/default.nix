{den, ...}: {
  den.aspects.desktop.addons.swaylock = {
    homeManager = {
      config,
      pkgs,
      ...
    }: {
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
        timeouts = [
          {
            timeout = 600;
            command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
            resumeCommand = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
          }
          {
            timeout = 610;
            command = "${pkgs.systemd}/bin/loginctl lock-session";
          }
        ];
      };
    };
  };
}
