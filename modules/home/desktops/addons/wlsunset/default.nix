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
      latitude = cfg.latitude;
      longitude = cfg.longitude;
    };
  };
}
