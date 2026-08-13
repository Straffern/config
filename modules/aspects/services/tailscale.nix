{den, ...}: {
  den.aspects.services.tailscale.nixos = {
    host,
    lib,
    ...
  }:
    {
      services.tailscale.enable = true;
      systemd.services.tailscaled = {
        environment.TS_DEBUG_HEALTH_LOGS = "false";
        serviceConfig.LogLevelMax = "notice";
      };
    }
    // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      environment.persistence."/persist".directories = ["/var/lib/tailscale"];
    };
}
