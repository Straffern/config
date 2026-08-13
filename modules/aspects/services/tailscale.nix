{den, ...}: {
  den.aspects.services.tailscale.nixos = {
    host,
    lib,
    ...
  }: {
    services.tailscale.enable = true;
    systemd.services.tailscaled = {
      environment.TS_DEBUG_HEALTH_LOGS = "false";
      serviceConfig.LogLevelMax = "notice";
    };
    environment.persistence."/persist".directories =
      lib.mkIf (host.hasAspect den.aspects.platform.impermanence)
      ["/var/lib/tailscale"];
  };
}
