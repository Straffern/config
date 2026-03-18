{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.${namespace}) enabled;
in {
  imports = [./disko.nix ./hardware-configuration.nix];

  ${namespace} = {
    system.boot.bios = enabled;
    system.boot.enable = lib.mkForce false;

    suites = {server.enable = true;};
    # suites.kubernetes = enabled;

    cli.programs.nix-ld = enabled;

    # AI Agent Gateway memory backend
    services.openviking = {
      enable = true;
      configFile = config.sops.templates."openviking-config".path;
    };

    user."1" = {
      name = "alex";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };

  sops.secrets."palantir_ssh_private_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "600";
    path = "/home/" + config.${namespace}.user."1".name + "/.ssh/id_ed25519";
    sopsFile = ../../../secrets.yaml;
  };

  sops.secrets."palantir_ssh_public_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "644";
    path =
      "/home/"
      + config.${namespace}.user."1".name
      + "/.ssh/id_ed25519.pub";
    sopsFile = ../../../secrets.yaml;
  };


  # ── OpenClaw Gateway (AI agent service) ─────────────────────────────
  # Secrets — add these to secrets.yaml via `sops secrets.yaml`:
  #   openclaw_auth_token: "<random-token>"
  #   openclaw_ai_api_key: "sk-..."
  #   openclaw_embedding_api_key: "sk-..." (embedding + VLM)
  #   openclaw_telegram_bot_alex: "<botfather-token>"
  #   openclaw_telegram_bot_gf: "<botfather-token>"

  sops.secrets."openclaw_auth_token" = {
    sopsFile = ../../../secrets.yaml;
    owner = "openclaw";
  };
  sops.secrets."openclaw_ai_api_key" = {
    sopsFile = ../../../secrets.yaml;
  };
  sops.secrets."openclaw_telegram_bot_alex" = {
    sopsFile = ../../../secrets.yaml;
    owner = "openclaw";
  };
  # sops.secrets."openclaw_telegram_bot_gf" = {
  #   sopsFile = ../../../secrets.yaml;
  # };

  sops.secrets."openclaw_embedding_api_key" = {
    sopsFile = ../../../secrets.yaml;
  };

  # OpenViking config (JSON) — secrets injected at activation via sops.templates
  sops.templates."openviking-config" = {
    content = builtins.toJSON {
      server = {
        host = "127.0.0.1";
        port = 1933;
      };
      storage = {
        workspace = "./data";  # container-relative (/app/data)
      };
      embedding = {
        dense = {
          provider = "openai";
          model = "text-embedding-3-large";
          api_key = config.sops.placeholder."openclaw_embedding_api_key";
          dimension = 3072;
        };
      };
      vlm = {
        provider = "openai";
        model = "gpt-4o";
        api_key = config.sops.placeholder."openclaw_embedding_api_key";
      };
    };
    mode = "0400";
    restartUnits = ["podman-openviking.service"];
  };

  # OpenClaw config (JSON) — secrets injected at activation via sops.templates
  sops.templates."openclaw-config" = {
    content = builtins.toJSON {
      # Gateway — loopback only, auth required
      gateway = {
        mode = "local";
        auth.token = config.sops.placeholder."openclaw_auth_token";
        bind = "loopback";
      };

      # Model — OpenCode Go catalog
      agents.defaults.model = {
        primary = "opencode-go/minimax-m2.7";
        fallbacks = ["opencode-go/kimi-k2.5" "opencode-go/minimax-m2.5"];
      };

      # Agents
      agents.list = [
        {
          id = "alex";
          name = "Alex";
          workspace = "/var/lib/openclaw/workspace-alex";
        }
        # {
        #   id = "gf";
        #   name = "GF";
        #   workspace = "/var/lib/openclaw/workspace-gf";
        # }
      ];

      # Route Telegram bot to agent
      bindings = [
        {agentId = "alex"; match = {channel = "telegram"; accountId = "alex";}; }
        # {agentId = "gf";   match = {channel = "telegram"; accountId = "gf";}; }
      ];

      # Telegram
      channels.telegram.enabled = true;
      channels.telegram.accounts = {
        alex = {
          botToken = config.sops.placeholder."openclaw_telegram_bot_alex";
          dmPolicy = "pairing";
          allowFrom = ["6045704025"];
        };
        # gf = {
        #   botToken = config.sops.placeholder."openclaw_telegram_bot_gf";
        #   dmPolicy = "pairing";
        # };
      };

      # Security hardening
      tools = {
        profile = "messaging";
        exec.ask = "always";
        elevated.enabled = false;
      };

      # Context-engine plugin — OpenViking (remote, connects to local container)
      plugins = {
        enabled = true;
        slots.contextEngine = "openviking";
        entries.openviking.config = {
          mode = "remote";
          baseUrl = "http://127.0.0.1:1933";
          autoRecall = true;
          autoCapture = true;
        };
      };
    };
    owner = "openclaw";
    mode = "0400";
    restartUnits = ["openclaw-gateway.service"];
  };

  # OpenClaw env file — secrets as env vars for runtime (memory search, etc.)
  sops.templates."openclaw-env" = {
    content = ''
      OPENAI_API_KEY=${config.sops.placeholder."openclaw_embedding_api_key"}
      OPENCODE_API_KEY=${config.sops.placeholder."openclaw_ai_api_key"}
    '';
    owner = "openclaw";
    mode = "0400";
  };

  services.openclaw-gateway = {
    enable = true;
    configFile = config.sops.templates."openclaw-config".path;
    environmentFiles = [config.sops.templates."openclaw-env".path];
    environment = {
      NODE_COMPILE_CACHE = "/var/lib/openclaw/.node-compile-cache";
      OPENCLAW_NO_RESPAWN = "1";
      # Allow the OpenViking plugin (copied to extensions/) to resolve
      # @sinclair/typebox from the openclaw package's node_modules.
      NODE_PATH = "${config.services.openclaw-gateway.package}/lib/openclaw/node_modules";
    };
  };

  # Ensure OpenClaw starts after OpenViking
  systemd.services.openclaw-gateway = {
    after = ["podman-openviking.service"];
    wants = ["podman-openviking.service"];
  };

  # Copy OpenViking plugin into openclaw's global extension dir on each start.
  # Cannot use symlinks: openclaw's security sandbox rejects plugins whose
  # realpath escapes the extensions root (Nix store symlinks fail this check).
  # NODE_PATH (above) provides @sinclair/typebox resolution.
  systemd.services.openclaw-gateway.serviceConfig.ExecStartPre = let
    pkg = config.services.openclaw-gateway.package;
    pluginSrc = "${pkg}/lib/openclaw/extensions/openviking";
    pluginDst = "/var/lib/openclaw/extensions/openviking";
  in [
    "+${pkgs.coreutils}/bin/mkdir -p /var/lib/openclaw/extensions"
    "+${pkgs.bash}/bin/bash -c 'rm -rf ${pluginDst} && cp -r ${pluginSrc} ${pluginDst} && chown -R openclaw:openclaw ${pluginDst}'"
  ];

  environment.systemPackages = [pkgs.home-manager pkgs.openclaw-gateway];

  programs.zsh.enable = true;

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "23.11";
  # ======================== DO NOT CHANGE THIS ========================
}
