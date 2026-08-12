{den, ...}: {
  den.aspects.desktop.addons.wlsunset = {
    homeManager = {lib, ...}: {
      services.wlsunset = {
        enable = true;
        latitude = "55.728760";
        longitude = "12.437280";
      };

      # Survive Hyprland crash restarts: add restart policy and wait for new Wayland socket
      systemd.user.services.wlsunset = {
        Unit = {
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
  };
}
