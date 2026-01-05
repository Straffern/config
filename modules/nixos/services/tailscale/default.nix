{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.tailscale;
in {
  options.${namespace}.services.tailscale = {
    enable = mkEnableOption "Tailscale";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    # Suppress frequent health check "ok" logs
    # See: https://github.com/tailscale/tailscale/issues/13650
    systemd.services.tailscaled.environment = {
      TS_DEBUG_HEALTH_LOGS = "false";
    };

    # Further reduce noise by setting log level to notice (hides INFO/6 logs)
    systemd.services.tailscaled.serviceConfig.LogLevelMax = "notice";

    # Persist node keys and authentication state
    ${namespace}.system.impermanence.directories = [ "/var/lib/tailscale" ];
  };
}
