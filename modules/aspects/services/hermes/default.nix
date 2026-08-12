{
  den,
  inputs,
  ...
}: let
  xurlPackage = pkgs: pkgs.callPackage ./_package/xurl {};
  hermesLinkPackage = pkgs: pkgs.callPackage ./_package/hermes-link {};
  dashboardPackage = pkgs: pkgs.callPackage ./_package/palantir-dashboard.nix {};
in {
  flake-file.inputs.hermes-agent = {
    url = "github:NousResearch/hermes-agent";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.services.hermes = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.services.hermes;
      hostSecretsFile = inputs.self + "/secrets/hosts/${config.networking.hostName}.yaml";
      xurl = xurlPackage pkgs;
      hermesLink = hermesLinkPackage pkgs;
      dashboardScript = dashboardPackage pkgs;
      hermesUser = config.services.hermes-agent.user;
      hermesGroup = config.services.hermes-agent.group;
      hermesStateDir = config.services.hermes-agent.stateDir;
      hermesWorkingDirectory = config.services.hermes-agent.workingDirectory;
      secretFrom = sopsFile: name: {${name}.sopsFile = sopsFile;};
      envLines =
        [
          "${cfg.model.apiKeyEnvVar}=${config.sops.placeholder.${cfg.model.apiKeySecret}}"
          "TELEGRAM_BOT_TOKEN=${config.sops.placeholder.${cfg.telegramBotTokenSecret}}"
          "TELEGRAM_ALLOWED_USERS=${lib.concatStringsSep "," cfg.telegramAllowedUsers}"
          "HINDSIGHT_MODE=local_external"
          "HINDSIGHT_API_URL=${cfg.hindsight.apiUrl}"
          "API_SERVER_ENABLED=true"
          "API_SERVER_HOST=127.0.0.1"
          "API_SERVER_PORT=8642"
          "API_SERVER_KEY=${config.sops.placeholder.${cfg.link.apiServerKeySecret}}"
        ]
        ++ lib.optional (cfg.web.exaApiKeySecret != null)
        "EXA_API_KEY=${config.sops.placeholder.${cfg.web.exaApiKeySecret}}"
        ++ lib.optional (cfg.browser.apiKeySecret != null)
        "BROWSER_USE_API_KEY=${config.sops.placeholder.${cfg.browser.apiKeySecret}}";
      baseSettings = {
        model = {
          default = cfg.model.default;
          provider = cfg.model.provider;
          base_url = cfg.model.baseUrl;
        };
        toolsets = ["all"];
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
          provider = "hindsight";
        };
        terminal.cwd = hermesWorkingDirectory;
      };
    in {
      imports = [inputs.hermes-agent.nixosModules.default];
      options.services.hermes = {
        link = {
          apiServerKeySecret = lib.mkOption {
            type = lib.types.str;
            default = "hermes_api_server_key";
          };
          apiServerKeySopsFile = lib.mkOption {
            type = lib.types.str;
            default = hostSecretsFile;
          };
        };
        telegramBotTokenSecret = lib.mkOption {
          type = lib.types.str;
          default = "telegram_bot_token";
        };
        telegramBotTokenSopsFile = lib.mkOption {
          type = lib.types.str;
          default = hostSecretsFile;
        };
        telegramAllowedUsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["6045704025"];
        };
        model = {
          provider = lib.mkOption {
            type = lib.types.str;
            default = "openrouter";
          };
          default = lib.mkOption {
            type = lib.types.str;
            default = "deepseek/deepseek-v4-flash";
          };
          baseUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://openrouter.ai/api/v1";
          };
          apiKeySecret = lib.mkOption {
            type = lib.types.str;
            default = "openrouter_api_key";
          };
          apiKeyEnvVar = lib.mkOption {
            type = lib.types.str;
            default = "OPENROUTER_API_KEY";
          };
          apiKeySopsFile = lib.mkOption {
            type = lib.types.str;
            default = hostSecretsFile;
          };
        };
        hindsight.apiUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8888";
        };
        web = {
          backend = lib.mkOption {
            type = lib.types.str;
            default = "exa";
          };
          exaApiKeySecret = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "exa_api_key";
          };
          exaApiKeySopsFile = lib.mkOption {
            type = lib.types.str;
            default = hostSecretsFile;
          };
        };
        browser = {
          apiKeySecret = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          apiKeySopsFile = lib.mkOption {
            type = lib.types.str;
            default = hostSecretsFile;
          };
        };
        xurl = {
          tokenSecret = lib.mkOption {
            type = lib.types.str;
            default = "x_bearer_token";
          };
          tokenSopsFile = lib.mkOption {
            type = lib.types.str;
            default = hostSecretsFile;
          };
        };
        settings = lib.mkOption {
          type = lib.types.attrs;
          default = {};
        };
      };
      config = {
        sops.secrets =
          secretFrom cfg.model.apiKeySopsFile cfg.model.apiKeySecret
          // secretFrom cfg.telegramBotTokenSopsFile cfg.telegramBotTokenSecret
          // secretFrom cfg.link.apiServerKeySopsFile cfg.link.apiServerKeySecret
          // lib.optionalAttrs (cfg.web.exaApiKeySecret != null) (
            secretFrom cfg.web.exaApiKeySopsFile cfg.web.exaApiKeySecret
          )
          // secretFrom cfg.xurl.tokenSopsFile cfg.xurl.tokenSecret
          // lib.optionalAttrs (cfg.browser.apiKeySecret != null) (
            secretFrom cfg.browser.apiKeySopsFile cfg.browser.apiKeySecret
          );
        sops.templates."hermes-env" = {
          content = lib.concatStringsSep "\n" envLines + "\n";
          owner = hermesUser;
          mode = "0400";
        };
        sops.templates."hermes-xurl-token" = {
          content = config.sops.placeholder.${cfg.xurl.tokenSecret};
          owner = hermesUser;
          mode = "0400";
        };
        environment.systemPackages = [
          xurl
          hermesLink
        ];
        services.hermes-agent = {
          enable = true;
          environmentFiles = [config.sops.templates."hermes-env".path];
          settings = lib.recursiveUpdate baseSettings (
            lib.recursiveUpdate {
              web = {
                backend = cfg.web.backend;
                search_backend = cfg.web.backend;
                extract_backend = cfg.web.backend;
              };
              browser.cloud_provider = "browser-use";
            }
            cfg.settings
          );
        };
        systemd.services.hermes-agent = {
          after = [
            "sops-nix.service"
            "podman-hindsight.service"
          ];
          wants = [
            "sops-nix.service"
            "podman-hindsight.service"
          ];
          restartTriggers = [
            config.sops.templates."hermes-env".content
            config.sops.templates."hermes-xurl-token".content
          ];
          preStart = ''umask 077; ${pkgs.coreutils}/bin/cat ${
              config.sops.templates."hermes-xurl-token".path
            } | ${xurl}/bin/xurl auth app-only - >/dev/null; ${pkgs.coreutils}/bin/chmod 0600 "$HOME/.xurl"'';
        };
        systemd.services.hermes-link = {
          description = "HermesPilot Link";
          wantedBy = ["multi-user.target"];
          after = [
            "network-online.target"
            "hermes-agent.service"
          ];
          wants = [
            "network-online.target"
            "hermes-agent.service"
          ];
          environment = {
            MESSAGING_CWD = hermesWorkingDirectory;
            HOME = hermesStateDir;
            HERMES_HOME = "${hermesStateDir}/.hermes";
            HERMESLINK_HOME = "${hermesStateDir}/.hermeslink";
            HERMESLINK_GATEWAY_AUTOSTART = "false";
          };
          serviceConfig = {
            User = hermesUser;
            Group = hermesGroup;
            WorkingDirectory = hermesStateDir;
            UMask = "0077";
            EnvironmentFile = config.sops.templates."hermes-env".path;
            ExecStart = "${hermesLink}/bin/hermeslink daemon";
            Restart = "always";
            RestartSec = "5s";
            RuntimeMaxSec = "12h";
          };
        };
        systemd.services.palantir-status-dashboard = lib.mkIf (config.networking.hostName == "palantir") {
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
        systemd.services.palantir-restart-hermes-link =
          lib.mkIf (config.networking.hostName == "palantir")
          {
            description = "Restart HermesPilot Link from dashboard";
            serviceConfig.Type = "oneshot";
            script = ''
              ${pkgs.coreutils}/bin/rm -f /run/palantir-status-dashboard/restart-hermes-link
              ${pkgs.systemd}/bin/systemctl restart hermes-link.service
            '';
          };
        systemd.paths.palantir-restart-hermes-link = lib.mkIf (config.networking.hostName == "palantir") {
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
    packages = {pkgs, ...}: {
      hermes-link = hermesLinkPackage pkgs;
      xurl = xurlPackage pkgs;
    };
  };
}
