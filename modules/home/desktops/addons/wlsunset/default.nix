{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.desktops.addons.wlsunset;
in {
  options.${namespace}.desktops.addons.wlsunset = {
    enable = mkEnableOption "Wlsunset night light";

    latitude = mkOption {
      type = types.str;
      default = "55.728760";
      description = "Latitude for location-based night light adjustment";
    };

    longitude = mkOption {
      type = types.str;
      default = "12.437280";
      description = "Longitude for location-based night light adjustment";
    };
  };

  config = mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      inherit (cfg) latitude longitude;
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
}
