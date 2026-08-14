{den, ...}: {
  den.aspects.services.hindsight-tailnet = {
    includes = [
      den.aspects.services.hindsight
      den.aspects.services.tailscale
    ];
    nixos = {config, ...}: {
      systemd.services.hindsight-tailscale-serve = {
        description = "Expose Hindsight on the tailnet";
        wantedBy = ["multi-user.target"];
        after = [
          "tailscaled.service"
          "network-online.target"
          "podman-hindsight.service"
        ];
        wants = [
          "tailscaled.service"
          "network-online.target"
          "podman-hindsight.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = [
            "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=8443 http://127.0.0.1:9999"
            "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=8444 http://127.0.0.1:8888"
          ];
          Restart = "on-failure";
          RestartSec = "15s";
        };
      };
    };
  };
}
