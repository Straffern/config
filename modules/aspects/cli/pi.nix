{
  den,
  inputs,
  ...
}: let
  pi = pkgs: inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
  herdr = pkgs: inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  tailscaleReadyCheck = pkgs:
    pkgs.writeShellScript "tailscale-ready-check" ''
      for i in $(seq 1 30); do
        if ${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null \
          | ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
          exit 0
        fi
        sleep 2
      done
      exit 1
    '';
in {
  den.aspects.cli.pi.homeManager = {pkgs, ...}: {
    home.packages = [
      (pi pkgs)
      (herdr pkgs)
    ];
  };

  den.aspects.cli.pi-dashboard.homeManager = {
    config,
    pkgs,
    ...
  }: {
    home.packages = [
      pkgs.nodejs_24
      pkgs.gcc
      pkgs.gnumake
      pkgs.python3
    ];
    home.file.".pi/dashboard/config.json".text = builtins.toJSON {
      port = 38081;
      piPort = 38099;
      autoStart = true;
      autoShutdown = false;
      shutdownIdleSeconds = 300;
      spawnStrategy = "headless";
      tunnel.enabled = false;
      modelProxy.enabled = false;
    };
    home.persistence."/persist".directories = [".pi"];
  };

  den.aspects.cli.pi-tailscale-serve.homeManager = {pkgs, ...}: {
    systemd.user.services.pi-dashboard-tailscale-serve = {
      Unit = {
        Description = "Expose Pi Agent Dashboard through Tailscale Serve";
      };
      Service = {
        Type = "oneshot";
        ExecCondition = "${tailscaleReadyCheck pkgs}";
        ExecStartPre = "-${pkgs.tailscale}/bin/tailscale serve --yes --http=38080 off";
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --http=38080 http://127.0.0.1:38081";
        ExecStop = "${pkgs.tailscale}/bin/tailscale serve --yes --http=38080 off";
        RemainAfterExit = true;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
