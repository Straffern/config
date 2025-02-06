{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.syncthing;
in {
  options.${namespace}.services.syncthing = {
    enable = mkEnableOption "Syncthing service";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray.enable = true;
      extraOptions = [ "--gui-address=127.0.0.1:8384" ];
    };
  };
}
