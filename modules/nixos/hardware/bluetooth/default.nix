{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.hardware.bluetoothctl;
in {
  options.hardware.bluetoothctl = {
    enable = mkEnableOption "Enable bluetooth service and packages";
  };

  config = mkIf cfg.enable {
    services.blueman.enable = true;
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = false;
        settings = { General = { Experimental = true; }; };
      };
    };
  };
}
