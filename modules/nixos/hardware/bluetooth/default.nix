{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.bluetoothctl;
in {
  options.${namespace}.hardware.bluetoothctl = {
    enable = mkEnableOption "Enable bluetooth service and packages";
  };

  config = mkIf cfg.enable {
    services.blueman.enable = true;
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = false;
        settings = {General = {Experimental = true;};};
      };
    };

    # Persist paired device keys and configurations
    ${namespace}.system.impermanence.directories = ["/var/lib/bluetooth"];
  };
}
