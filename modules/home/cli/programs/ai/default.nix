{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    mkMerge
    types
    ;
  cfg = config.${namespace}.cli.programs.ai;
  nodePackage = pkgs.nodejs_24;
  opencodePackage = pkgs.opencode-patched;
  opencodeServerUrl = "http://${cfg.opencode.server.hostname}:${toString cfg.opencode.server.port}";
  opencodeEphemeralWrapper = pkgs.writeShellApplication {
    name = "ocn";
    text = ''
      real_opencode=${opencodePackage}/bin/opencode
      tailscale=${pkgs.tailscale}/bin/tailscale
      port=${toString (cfg.opencode.server.port + 1)}

      while (: >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1; do
        port=$((port + 1))
      done

      cleanup() {
        "$tailscale" serve --yes --http="$port" off >/dev/null 2>&1 || true
      }
      trap cleanup EXIT INT TERM

      "$tailscale" serve --bg --yes --http="$port" "http://127.0.0.1:$port"
      "$real_opencode" --port "$port" "$@"
    '';
  };
  opencodeWrapper = pkgs.writeShellApplication {
    name = "opencode";
    text = ''
      real_opencode=${opencodePackage}/bin/opencode
      server_url=${opencodeServerUrl}

      case "''${1:-}" in
        -h|--help|-v|--version|serve|attach|web|debug|providers|auth|mcp|agent|plugin|db|completion|upgrade|uninstall|models|stats|export|import|github|pr|session|acp)
          exec "$real_opencode" "$@"
          ;;
        run)
          shift
          exec "$real_opencode" run --attach "$server_url" --dir "$PWD" "$@"
          ;;
      esac

      if [[ $# -gt 0 && -d "$1" ]]; then
        dir=$1
        shift
        exec "$real_opencode" attach "$server_url" --dir "$dir" "$@"
      fi

      exec "$real_opencode" attach "$server_url" --dir "$PWD" "$@"
    '';
  };
  kittylitterLauncher = pkgs.writeShellApplication {
    name = "kittylitter-service";
    runtimeInputs = with pkgs; [
      nodePackage
    ];
    text = ''
      export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.local/cache/.bun/bin:$HOME/.cargo/bin:/run/wrappers/bin:$HOME/.nix-profile/bin:/nix/profile/bin:$HOME/.local/state/nix/profile/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"
      exec ${nodePackage}/bin/npx --yes kittylitter serve
    '';
  };
in {
  options = {
    programs.opencode.tui.theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Compatibility option for Stylix until Home Manager exposes OpenCode tui.json settings.";
    };

    ${namespace}.cli.programs.ai = {
      enable = mkEnableOption "AI tools";

      opencode = {
        enable = mkEnableOption "OpenCode configuration";

        server = {
          enable = mkEnableOption "shared OpenCode server";

          hostname = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Hostname for the shared OpenCode server to listen on.";
          };

          port = mkOption {
            type = types.port;
            default = 37575;
            description = "Port for the shared OpenCode server.";
          };
        };

        wrapper = {
          enable = mkEnableOption "OpenCode wrapper that attaches to the shared server";
        };

        kittylitter = {
          enable = mkEnableOption "Kittylitter service using the shared OpenCode server";
        };

        tailscaleServe = {
          enable = mkEnableOption "Tailscale Serve exposure for the shared OpenCode server";
        };
      };

      shellFunction = {
        enable = mkEnableOption "AI command generator zsh function";

        model = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "anthropic/claude-opus-4-1-20250805";
          description = ''
            Model to use for command generation.
            If null, uses OpenCode's configured default model.
          '';
        };

        systemPrompt = mkOption {
          type = types.str;
          default = "Generate ONLY the exact shell command needed. No explanations, no markdown, no formatting - just the raw command. DO NOT USE ANY TOOLS.";
          description = "System prompt for command generation";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs.opencode = lib.mkIf cfg.opencode.enable {
      enable = true;
      package =
        if cfg.opencode.wrapper.enable
        then opencodeWrapper
        else opencodePackage;
    };

    home.file = mkMerge [
      (lib.mkIf cfg.opencode.enable {
        ".config/opencode/AGENTS.md" = {
          source = config.lib.asgaard.managedSource ./AGENTS.md;
        };
      })
    ];

    home.packages = mkMerge [
      (mkIf cfg.opencode.kittylitter.enable [
        nodePackage
      ])
      (mkIf cfg.opencode.server.enable [
        opencodeEphemeralWrapper
        pkgs.tree
      ])
    ];

    systemd.user.services = mkMerge [
      (mkIf cfg.opencode.server.enable {
        opencode-server = {
          Unit = {
            Description = "Shared OpenCode server";
            After = ["network.target"];
          };

          Service = {
            Type = "simple";
            ExecStart = "${opencodePackage}/bin/opencode serve --hostname ${cfg.opencode.server.hostname} --port ${toString cfg.opencode.server.port}";
            Restart = "on-failure";
            RestartSec = 5;
          };

          Install.WantedBy = ["default.target"];
        };
      })

      (mkIf cfg.opencode.kittylitter.enable {
        kittylitter = {
          Unit = {
            Description = "Alleycat bridge daemon";
            After = ["network-online.target" "opencode-server.service"];
            Wants = ["opencode-server.service"];
          };

          Service = {
            Type = "simple";
            ExecStart = "${kittylitterLauncher}/bin/kittylitter-service";
            Environment = [
              "OPENCODE_BRIDGE_BACKEND_URL=${opencodeServerUrl}"
            ];
            Restart = "on-failure";
            RestartSec = 5;
          };

          Install.WantedBy = ["default.target"];
        };
      })

      (mkIf cfg.opencode.tailscaleServe.enable {
        opencode-tailscale-serve = {
          Unit = {
            Description = "Expose OpenCode through Tailscale Serve";
            After = ["opencode-server.service"];
            Wants = ["opencode-server.service"];
          };

          Service = {
            Type = "oneshot";
            ExecStartPre = "-${pkgs.tailscale}/bin/tailscale serve --yes --http=80 off";
            ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --http=${toString cfg.opencode.server.port} ${opencodeServerUrl}";
            ExecStop = "${pkgs.tailscale}/bin/tailscale serve --yes --http=${toString cfg.opencode.server.port} off";
            RemainAfterExit = true;
          };

          Install.WantedBy = ["default.target"];
        };
      })
    ];

    # AI shell command generator function
    ${namespace} = {
      cli.shells.zsh.initContent = lib.mkIf cfg.shellFunction.enable (
        let
          ai-shell-function = (pkgs.callPackage ../../../../../packages/ai-shell {}) {
            inherit (cfg.shellFunction) model systemPrompt;
          };
        in ''
          # Load ai command generator function
          source ${ai-shell-function}
        ''
      );

      system.persistence = {
        directories = [
          ".config/opencode"
        ];
      };
    };
  };
}
