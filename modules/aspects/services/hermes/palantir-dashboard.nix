{den, ...}: let
  dashboardPackage = pkgs: pkgs.callPackage ./_package/palantir-dashboard.nix {};
in {
  den.aspects.services.hermes-palantir-dashboard = {
    includes = [
      den.aspects.services.hermes
      den.aspects.services.tailscale
    ];
    nixos = {
      config,
      pkgs,
      ...
    }: let
      dashboardScript = dashboardPackage pkgs;
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
      systemd.services.palantir-status-dashboard = {
        description = "Serve the Palantir service status dashboard";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          ExecStart = "${pkgs.python3}/bin/python ${dashboardScript}";
          DynamicUser = true;
          RuntimeDirectory = "palantir-status-dashboard";
          RuntimeDirectoryMode = "0750";
          Restart = "always";
          RestartSec = 2;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
      systemd.services.hermes-tailscale-serve = {
        description = "Expose Hermes on the tailnet";
        wantedBy = ["multi-user.target"];
        after = [
          "tailscaled.service"
          "network-online.target"
          "palantir-status-dashboard.service"
        ];
        wants = [
          "tailscaled.service"
          "network-online.target"
          "palantir-status-dashboard.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStartPre = tailscaleReadyCheck;
          ExecStart = [
            "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --http=80 http://127.0.0.1:8080"
            "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=443 http://127.0.0.1:8080"
          ];
          Restart = "on-failure";
          RestartSec = "15s";
        };
      };
      systemd.services.palantir-restart-hermes-link = {
        description = "Restart HermesPilot Link from dashboard";
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.coreutils}/bin/rm -f /run/palantir-status-dashboard/restart-hermes-link
          ${pkgs.systemd}/bin/systemctl restart hermes-link.service
        '';
      };
      systemd.paths.palantir-restart-hermes-link = {
        description = "Watch for HermesPilot Link dashboard restart requests";
        wantedBy = ["multi-user.target"];
        after = ["palantir-status-dashboard.service"];
        pathConfig = {
          PathExists = "/run/palantir-status-dashboard/restart-hermes-link";
          Unit = "palantir-restart-hermes-link.service";
        };
      };
    };
  };
}
