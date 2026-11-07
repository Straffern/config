# Public GitHub webhook ingress for Robomp: Tailscale Funnel exposes only
# /webhook/github; /healthz, /events, /issues, /replay and the dashboard stay
# loopback-only. The node needs the tailnet `funnel` nodeAttr.
{den, ...}: {
  den.aspects.services.robomp-funnel = {
    includes = [
      den.aspects.services.robomp
      den.aspects.services.tailscale
    ];
    vmSmoke = [
      {
        name = "robomp-funnel-skipped";
        description = "Robomp Funnel stays off without Tailscale identity";
        phase = "boot";
        module = {lib, ...}: {
          systemd.services.robomp-funnel.wantedBy = lib.mkForce [];
        };
      }
    ];
    nixos = {
      config,
      lib,
      ...
    }: let
      tailscale = "${config.services.tailscale.package}/bin/tailscale";
      webhook = "http://127.0.0.1:${toString config.services.robomp.listen.port}/webhook/github";
    in {
      systemd.services.robomp-funnel = lib.mkIf config.services.robomp.enable {
        description = "Expose the Robomp GitHub webhook through Tailscale Funnel";
        wantedBy = ["multi-user.target"];
        after = [
          "tailscaled.service"
          "network-online.target"
          "robomp.service"
        ];
        wants = [
          "tailscaled.service"
          "network-online.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${tailscale} funnel --yes --bg --https=10000 --set-path=/webhook/github ${webhook}";
          ExecStop = "${tailscale} funnel --yes --https=10000 --set-path=/webhook/github off";
          Restart = "on-failure";
          RestartSec = "15s";
        };
      };
    };
  };
}
