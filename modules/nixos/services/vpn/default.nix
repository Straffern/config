{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.vpn;
in {
  options.services.vpn = { enable = mkEnableOption "VPN"; };

  config = mkIf cfg.enable {
    networking.wireguard.enable = true;
    services.tailscale.enable = true;

  };
}
