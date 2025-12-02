{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.services.vpn;
in {
  options.${namespace}.services.vpn = { enable = mkEnableOption "VPN"; };

  config = mkIf cfg.enable {
    networking.wireguard.enable = true;

    # Use namespace pattern to enable tailscale (which handles its own persistence)
    ${namespace}.services.tailscale = enabled;
  };
}
