{
  den,
  inputs,
  lib,
  ...
}: {
  den.aspects.services.robomp.nixos = {
    config,
    host,
    pkgs,
    ...
  }: let
    omp = pkgs.callPackage ../../cli/omp/_package {};
    cfg = config.services.robomp;
    robomp = pkgs.callPackage ./_package {};
    stateDir = "/var/lib/robomp";
    agentHome = "${stateDir}/agent";
    proxyHome = "${stateDir}/proxy";
    dataDir = "${stateDir}/data";
    agentUser = "robomp";
    agentGroup = "robomp";
    proxyUser = "robomp-proxy";
    proxyGroup = "robomp-proxy";
    sharedGroup = "robomp-shared";
    minterUser = "robomp-minter";
    tokenDir = "/run/robomp-github";
    tokenFile = "${tokenDir}/token";
    piRoot = robomp.passthru.piRoot;
    scalarType = lib.types.oneOf [
      lib.types.str
      lib.types.int
      lib.types.bool
    ];
    reservedSettingKeys = [
      "GITHUB_TOKEN"
      "GITHUB_WEBHOOK_SECRET"
      "PI_ROOT"
      "ROBOMP_BIND_HOST"
      "ROBOMP_BIND_PORT"
      "ROBOMP_BOT_LOGIN"
      "ROBOMP_GH_PROXY_BIND_HOST"
      "ROBOMP_GH_PROXY_BIND_PORT"
      "ROBOMP_GH_PROXY_HMAC_KEY"
      "ROBOMP_GH_PROXY_URL"
      "ROBOMP_GH_PROXY_TOKEN_FILE"
      "ROBOMP_GIT_AUTHOR_EMAIL"
      "ROBOMP_GIT_AUTHOR_NAME"
      "ROBOMP_LOG_DIR"
      "ROBOMP_MAINTAINER_LOGINS"
      "ROBOMP_MODEL"
      "ROBOMP_NATIVES_CACHE_ROOT"
      "ROBOMP_OMP_COMMAND"
      "ROBOMP_PROVIDER"
      "ROBOMP_REPO_ALLOWLIST"
      "ROBOMP_REPLAY_TOKEN"
      "ROBOMP_REVIEWER_BOTS"
      "ROBOMP_SQLITE_PATH"
      "ROBOMP_THINKING"
      "ROBOMP_WORKSPACE_ROOT"
    ];
    renderValue = value:
      if builtins.isBool value
      then lib.boolToString value
      else toString value;
    renderEnvironment = attrs:
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "${name}=${lib.escapeShellArg (renderValue value)}") attrs
      )
      + "\n";
    commonEnvironment = {
      GITHUB_WEBHOOK_SECRET = config.sops.placeholder.${cfg.secrets.webhookSecretKey};
      ROBOMP_BOT_LOGIN = cfg.bot.login;
      ROBOMP_GH_PROXY_HMAC_KEY = config.sops.placeholder.${cfg.secrets.proxyHmacKey};
      ROBOMP_GIT_AUTHOR_EMAIL = "${toString cfg.app.botUserId}+${cfg.bot.login}[bot]@users.noreply.github.com";
      ROBOMP_GIT_AUTHOR_NAME = "${cfg.bot.login}[bot]";
      ROBOMP_LOG_DIR = "${dataDir}/logs";
      ROBOMP_MAINTAINER_LOGINS = lib.concatStringsSep "," cfg.bot.maintainers;
      ROBOMP_MODEL = cfg.model.id;
      ROBOMP_NATIVES_CACHE_ROOT = "${dataDir}/cache/pi-natives";
      ROBOMP_OMP_COMMAND = "omp";
      ROBOMP_PROVIDER = cfg.model.provider;
      ROBOMP_REPO_ALLOWLIST = lib.concatStringsSep "," cfg.repositories;
      ROBOMP_REVIEWER_BOTS = lib.concatStringsSep "," cfg.bot.reviewerBots;
      ROBOMP_SQLITE_PATH = "${dataDir}/robomp.sqlite";
      ROBOMP_THINKING = cfg.model.thinking;
      ROBOMP_WORKSPACE_ROOT = "${dataDir}/workspaces";
      PI_ROOT = piRoot;
    };
    orchestratorEnvironment =
      commonEnvironment
      // cfg.settings
      // {
        ROBOMP_BIND_HOST = cfg.listen.address;
        ROBOMP_BIND_PORT = cfg.listen.port;
        ROBOMP_GH_PROXY_URL = "http://127.0.0.1:8081";
      };
    proxyEnvironment =
      commonEnvironment
      // cfg.settings
      // {
        ROBOMP_GH_PROXY_TOKEN_FILE = tokenFile;
        ROBOMP_GH_PROXY_BIND_HOST = "127.0.0.1";
        ROBOMP_GH_PROXY_BIND_PORT = 8081;
      };
    hardening = {
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = false;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      ReadWritePaths = [stateDir];
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0007";
    };
    # Installation tokens last an hour. Each mint narrows the token to the allowlisted
    # repositories and the permissions robomp uses, whatever else the App is granted.
    mintToken = pkgs.writeShellApplication {
      name = "robomp-mint-github-token";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.jq
        pkgs.openssl
      ];
      text = ''
        b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
        now=$(date +%s)
        header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
        claims=$(printf '{"iat":%d,"exp":%d,"iss":"%d"}' "$((now - 60))" "$((now + 540))" ${toString cfg.app.id} | b64url)
        signature=$(printf '%s.%s' "$header" "$claims" | openssl dgst -sha256 -sign "$CREDENTIALS_DIRECTORY/app-key" -binary | b64url)
        token=$(
          curl --fail-with-body --silent --show-error --request POST \
            --header "Authorization: Bearer $header.$claims.$signature" \
            --header "Accept: application/vnd.github+json" \
            --header "X-GitHub-Api-Version: 2022-11-28" \
            --data ${lib.escapeShellArg (builtins.toJSON {
          repositories = map (repo: lib.last (lib.splitString "/" repo)) cfg.repositories;
          permissions = {
            contents = "write";
            issues = "write";
            metadata = "read";
            pull_requests = "write";
          };
        })} \
            https://api.github.com/app/installations/${toString cfg.app.installationId}/access_tokens |
            jq --exit-status --raw-output .token
        )
        tmp=$(mktemp ${tokenDir}/.token.XXXXXX)
        printf '%s\n' "$token" >"$tmp"
        chmod 0440 "$tmp"
        mv --force "$tmp" ${tokenFile}
      '';
    };
    serviceConfig =
      {
        WorkingDirectory = stateDir;
        Restart = "always";
        RestartSec = "5s";
        TimeoutStopSec = "30s";
        KillMode = "mixed";
      }
      // hardening;
  in {
    options.services.robomp = {
      enable = lib.mkEnableOption "the Robomp GitHub webhook orchestrator";
      repositories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Exact GitHub owner/repo allowlist managed by this Robomp instance.";
      };
      bot = {
        login = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "GitHub App slug. Robomp answers @<slug> mentions and acts as <slug>[bot].";
        };
        maintainers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "GitHub logins authorized as Robomp maintainers.";
        };
        reviewerBots = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "GitHub bot logins whose reviews Robomp recognizes.";
        };
      };
      app = {
        id = lib.mkOption {
          type = lib.types.ints.positive;
          description = "GitHub App ID, from the App's settings page.";
        };
        installationId = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Installation ID of the App on the repositories' owner, from the installation settings URL.";
        };
        botUserId = lib.mkOption {
          type = lib.types.ints.positive;
          description = "User ID of <slug>[bot], used in the bot's noreply commit email: `gh api '/users/<slug>%5Bbot%5D' --jq .id`.";
        };
      };
      model = {
        id = lib.mkOption {
          type = lib.types.str;
          default = "openai-codex/gpt-5.3-codex";
          description = "Robomp model identifier.";
        };
        provider = lib.mkOption {
          type = lib.types.str;
          default = "openai-codex";
          description = "OMP provider for the configured Robomp model.";
        };
        thinking = lib.mkOption {
          type = lib.types.enum [
            "off"
            "low"
            "medium"
            "high"
            "xhigh"
            "max"
          ];
          default = "high";
          description = "OMP thinking level for Robomp tasks.";
        };
      };
      secrets = {
        sopsFile = lib.mkOption {
          type = lib.types.path;
          default = inputs.self + "/secrets/hosts/${host.name}.yaml";
          description = "SOPS file containing the App private key, webhook secret, and proxy HMAC key.";
        };
        appPrivateKeyKey = lib.mkOption {
          type = lib.types.str;
          default = "robomp_app_private_key";
          description = "SOPS key holding the GitHub App private key (PEM). Only the token minter reads it.";
        };
        webhookSecretKey = lib.mkOption {
          type = lib.types.str;
          default = "robomp_webhook_secret";
          description = "SOPS key holding the GitHub webhook signature secret.";
        };
        proxyHmacKey = lib.mkOption {
          type = lib.types.str;
          default = "robomp_proxy_hmac_key";
          description = "SOPS key holding the Robomp-to-proxy HMAC key.";
        };
      };
      listen = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Webhook listener address. The default is loopback; a consumer must provide authenticated public HTTPS ingress for GitHub webhooks. This aspect creates no public listener or tunnel.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Webhook listener port behind the consumer-provided public HTTPS ingress.";
        };
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf scalarType;
        default = {};
        description = "Advanced non-secret ROBOMP_* environment overrides. Strings, integers, and booleans are rendered safely; booleans use lowercase upstream spelling.";
      };
      openaiCodexLoginCommand = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "sudo -u ${agentUser} env HOME=${agentHome} ${omp}/bin/omp";
        description = "One-time interactive OpenAI Codex subscription login. Run this command as an operator, enter /login, and select openai-codex so OMP persists its refreshable credential database in the service HOME; OAuth is never automated by this module.";
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = !cfg.enable || cfg.repositories != [];
            message = "services.robomp.repositories must be nonempty when services.robomp.enable is true.";
          }
          {
            assertion = !cfg.enable || cfg.bot.login != "";
            message = "services.robomp.bot.login must be nonempty when services.robomp.enable is true.";
          }
          {
            assertion = lib.all (name: builtins.match "ROBOMP_[A-Z0-9_]+" name != null) (
              builtins.attrNames cfg.settings
            );
            message = "services.robomp.settings keys must be uppercase ROBOMP_* environment variable names.";
          }
          {
            assertion = lib.all (name: !(lib.elem name reservedSettingKeys)) (builtins.attrNames cfg.settings);
            message = "services.robomp.settings cannot override secret or module-managed core environment keys.";
          }
          {
            assertion = lib.all (
              value: !builtins.isString value || (!lib.hasInfix "\n" value && !lib.hasInfix "\r" value)
            ) (builtins.attrValues cfg.settings);
            message = "services.robomp.settings string values must not contain newlines.";
          }
          {
            assertion = !cfg.enable || lib.length (lib.unique (map (repo: lib.head (lib.splitString "/" repo)) cfg.repositories)) == 1;
            message = "services.robomp.repositories must share one owner: a GitHub App installation token covers a single account.";
          }
        ];
      }
      (lib.mkIf cfg.enable {
        sops.secrets = {
          "${cfg.secrets.appPrivateKeyKey}".sopsFile = cfg.secrets.sopsFile;
          "${cfg.secrets.webhookSecretKey}".sopsFile = cfg.secrets.sopsFile;
          "${cfg.secrets.proxyHmacKey}".sopsFile = cfg.secrets.sopsFile;
        };
        sops.templates."robomp-env" = {
          content = renderEnvironment orchestratorEnvironment;
          owner = "root";
          group = "root";
          mode = "0400";
          restartUnits = ["robomp.service"];
        };
        sops.templates."robomp-gh-proxy-env" = {
          content = renderEnvironment proxyEnvironment;
          owner = "root";
          group = "root";
          mode = "0400";
          restartUnits = ["robomp-gh-proxy.service"];
        };
        users.groups = {
          ${agentGroup} = {};
          ${proxyGroup} = {};
          ${sharedGroup} = {};
        };
        users.users.${agentUser} = {
          isSystemUser = true;
          group = agentGroup;
          extraGroups = [sharedGroup];
          home = agentHome;
          createHome = false;
        };
        users.users.${proxyUser} = {
          isSystemUser = true;
          group = proxyGroup;
          extraGroups = [sharedGroup];
          home = proxyHome;
          createHome = false;
        };
        users.groups.${minterUser} = {};
        users.users.${minterUser} = {
          isSystemUser = true;
          group = minterUser;
        };
        systemd.tmpfiles.rules = [
          "d ${stateDir} 0710 root ${sharedGroup} -"
          "d ${agentHome} 0700 ${agentUser} ${agentGroup} -"
          "d ${proxyHome} 0700 ${proxyUser} ${proxyGroup} -"
          "d ${dataDir} 2770 root ${sharedGroup} -"
          "d ${dataDir}/cache 2770 root ${sharedGroup} -"
          "d ${dataDir}/cache/pi-natives 2770 root ${sharedGroup} -"
          "d ${dataDir}/logs 2770 root ${sharedGroup} -"
          "d ${dataDir}/workspaces 2770 root ${sharedGroup} -"
          "d ${tokenDir} 2750 ${minterUser} ${proxyGroup} -"
        ];
        systemd.services.robomp-github-token = {
          description = "Mint the Robomp GitHub App installation token";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig =
            hardening
            // {
              Type = "oneshot";
              User = minterUser;
              Group = minterUser;
              LoadCredential = "app-key:${config.sops.secrets.${cfg.secrets.appPrivateKeyKey}.path}";
              ReadWritePaths = [tokenDir];
              ExecStart = lib.getExe mintToken;
              Restart = "on-failure";
              RestartSec = "30s";
            };
        };
        systemd.timers.robomp-github-token = {
          wantedBy = ["timers.target"];
          timerConfig.OnUnitActiveSec = "30min";
        };
        systemd.services.robomp-gh-proxy = {
          description = "Robomp GitHub API proxy";
          wantedBy = ["multi-user.target"];
          after = [
            "network-online.target"
            "robomp-github-token.service"
          ];
          wants = [
            "network-online.target"
            "robomp-github-token.service"
          ];
          restartTriggers = [config.sops.templates."robomp-gh-proxy-env".content];
          path = [
            pkgs.git
            pkgs.openssh
          ];
          environment = {
            HOME = proxyHome;
            GIT_CONFIG_GLOBAL = "${proxyHome}/.gitconfig";
          };
          serviceConfig =
            serviceConfig
            // {
              User = proxyUser;
              Group = proxyGroup;
              SupplementaryGroups = [sharedGroup];
              EnvironmentFile = config.sops.templates."robomp-gh-proxy-env".path;
              ExecStartPre = "${pkgs.coreutils}/bin/install -m 0600 ${pkgs.writeText "robomp-proxy-gitconfig" ''
                [safe]
                  directory = ${dataDir}/workspaces/*
              ''} ${proxyHome}/.gitconfig";
              ExecStart = "${robomp.passthru.python}/bin/python -m robomp.proxy serve";
            };
        };
        systemd.services.robomp = {
          description = "Robomp GitHub webhook orchestrator";
          wantedBy = ["multi-user.target"];
          after = [
            "network-online.target"
            "robomp-gh-proxy.service"
          ];
          wants = ["network-online.target"];
          requires = ["robomp-gh-proxy.service"];
          restartTriggers = [config.sops.templates."robomp-env".content];
          path = [
            pkgs.git
            pkgs.openssh
            pkgs.bun
          ];
          environment.HOME = agentHome;
          serviceConfig =
            serviceConfig
            // {
              User = agentUser;
              Group = agentGroup;
              SupplementaryGroups = [sharedGroup];
              EnvironmentFile = config.sops.templates."robomp-env".path;
              ExecStart = "${robomp}/bin/robomp serve";
            };
        };
      })
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        environment.persistence."/persist".directories = lib.mkIf cfg.enable [stateDir];
      })
    ];
  };
}
