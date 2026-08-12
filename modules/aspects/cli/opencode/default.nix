{
  den,
  inputs,
  ...
}: let
  opencode = pkgs: inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

  opencodeEphemeralWrapper = pkgs: let
    package = opencode pkgs;
  in
    pkgs.writeShellApplication {
      name = "ocn";
      text = ''
        real_opencode=${package}/bin/opencode
        tailscale=${pkgs.tailscale}/bin/tailscale
        port=37576
        while (: >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1; do port=$((port + 1)); done
        cleanup() { "$tailscale" serve --yes --http="$port" off >/dev/null 2>&1 || true; }
        trap cleanup EXIT INT TERM
        "$tailscale" serve --bg --yes --http="$port" "http://127.0.0.1:$port"
        "$real_opencode" --port "$port" "$@"
      '';
    };

  opencodeWrapper = pkgs: let
    package = opencode pkgs;
  in
    pkgs.writeShellApplication {
      name = "opencode";
      text = ''
        real_opencode=${package}/bin/opencode
        server_url=http://127.0.0.1:37575
        case "''${1:-}" in
          -h|--help|-v|--version|serve|attach|web|debug|providers|auth|mcp|agent|plugin|db|completion|upgrade|uninstall|models|stats|export|import|github|pr|session|acp)
            exec "$real_opencode" "$@" ;;
          run)
            shift
            exec "$real_opencode" run --attach "$server_url" --dir "$PWD" "$@" ;;
        esac
        if [[ $# -gt 0 && -d "$1" ]]; then
          dir=$1
          shift
          exec "$real_opencode" attach "$server_url" --dir "$dir" "$@"
        fi
        exec "$real_opencode" attach "$server_url" --dir "$PWD" "$@"
      '';
    };

  kittylitterLauncher = pkgs:
    pkgs.writeShellApplication {
      name = "kittylitter-service";
      runtimeInputs = [pkgs.nodejs_24];
      text = "exec ${pkgs.nodejs_24}/bin/npx --yes kittylitter@latest serve";
    };

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

  managedSource = config: path:
    if config.mutableSources.active
    then config.lib.file.mkOutOfStoreSymlink (toString path)
    else path;
in {
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "unstable";
  };
  den.aspects.cli.opencode.homeManager = {
    config,
    pkgs,
    ...
  }: {
    programs.opencode = {
      enable = true;
      package = opencode pkgs;
    };
    home.file.".config/opencode/AGENTS.md".source = managedSource config ./_data/AGENTS.md;
    home.persistence."/persist".directories = [".config/opencode"];
  };

  den.aspects.cli.opencode-server.homeManager = {pkgs, ...}: {
    home.packages = [
      (opencodeEphemeralWrapper pkgs)
      pkgs.tree
    ];
    systemd.user.services.opencode-server = {
      Unit = {
        Description = "Shared OpenCode server";
        After = ["network.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${opencode pkgs}/bin/opencode serve --hostname 127.0.0.1 --port 37575";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };
  };

  den.aspects.cli.opencode-wrapper.homeManager = {pkgs, ...}: {
    programs.opencode.package = opencodeWrapper pkgs;
  };

  den.aspects.cli.kittylitter.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.nodejs_24];
    systemd.user.services.kittylitter = {
      Unit = {
        Description = "Alleycat bridge daemon";
        After = [
          "network-online.target"
          "opencode-server.service"
        ];
        Wants = ["opencode-server.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${kittylitterLauncher pkgs}/bin/kittylitter-service";
        Environment = ["OPENCODE_BRIDGE_BACKEND_URL=http://127.0.0.1:37575"];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };
  };

  den.aspects.cli.opencode-tailscale-serve.homeManager = {pkgs, ...}: {
    systemd.user.services.opencode-tailscale-serve = {
      Unit = {
        Description = "Expose OpenCode through Tailscale Serve";
        After = ["opencode-server.service"];
        Wants = ["opencode-server.service"];
      };
      Service = {
        Type = "oneshot";
        ExecCondition = "${tailscaleReadyCheck pkgs}";
        ExecStartPre = "-${pkgs.tailscale}/bin/tailscale serve --yes --http=37575 off";
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --http=37575 http://127.0.0.1:37575";
        ExecStop = "${pkgs.tailscale}/bin/tailscale serve --yes --http=37575 off";
        RemainAfterExit = true;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
