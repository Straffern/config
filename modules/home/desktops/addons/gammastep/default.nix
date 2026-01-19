{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.gammastep;
in {
  options.${namespace}.desktops.addons.gammastep = {
    enable = mkEnableOption "Gammastep night light";
  };

  config = mkIf cfg.enable {
    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 6000;
        night = 4600;
      };
      settings = {general.adjustment-method = "wayland";};
    };
  };
}
