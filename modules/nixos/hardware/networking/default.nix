{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.networking;
in {
  options.${namespace}.hardware.networking = {
    enable = mkEnableOption "NetworkManager";
  };

  config = mkIf cfg.enable {
    networking.firewall = { enable = true; };
    networking.networkmanager.enable = true;
  };
}
