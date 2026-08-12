{den, ...}: {
  den.aspects.services.tailscale.nixos = {
    config,
    host,
    lib,
    pkgs,
    ...
  }: let
    tailscaleReadyCheck = pkgs.writeShellScript "palantir-tailscale-ready" ''
      for attempt in $(seq 1 30); do
        if ${pkgs.curl}/bin/curl --silent --fail http://127.0.0.1:8080/ >/dev/null &&
          ${config.services.tailscale.package}/bin/tailscale status --json 2>/dev/null |
            ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
          exit 0
        fi
        sleep 2
      done
      exit 1
    '';
  in {
    services.tailscale.enable = true;
    systemd.services.tailscaled = {
      environment.TS_DEBUG_HEALTH_LOGS = "false";
      serviceConfig.LogLevelMax = "notice";
    };
    environment.persistence."/persist".directories =
      lib.mkIf (host.hasAspect den.aspects.platform.impermanence)
      ["/var/lib/tailscale"];
    systemd.services.tailscale-hindsight-serve = lib.mkIf (config.networking.hostName == "palantir") {
      description = "Expose Palantir services on the tailnet";
      wantedBy = ["multi-user.target"];
      after = [
        "tailscaled.service"
        "network-online.target"
        "palantir-status-dashboard.service"
        "podman-hindsight.service"
      ];
      wants = [
        "tailscaled.service"
        "network-online.target"
        "palantir-status-dashboard.service"
        "podman-hindsight.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = tailscaleReadyCheck;
        ExecStart = [
          "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --http=80 http://127.0.0.1:8080"
          "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=443 http://127.0.0.1:8080"
          "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=8443 http://127.0.0.1:9999"
          "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=8444 http://127.0.0.1:8888"
        ];
        Restart = "on-failure";
        RestartSec = "15s";
      };
    };
  };
}
