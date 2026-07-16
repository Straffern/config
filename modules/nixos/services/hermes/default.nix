{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}: let
  cfg = config.${namespace}.services.hermes;
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  flakeDir = lib.${namespace}.flakeDir inputs;
  hostSecretsFile = flakeDir "secrets/hosts/${config.networking.hostName}.yaml";
  hermesUser = config.services.hermes-agent.user;
  hermesGroup = config.services.hermes-agent.group;
  hermesStateDir = config.services.hermes-agent.stateDir;
  hermesWorkingDirectory = config.services.hermes-agent.workingDirectory;

  secretFrom = sopsFile: name: {
    ${name}.sopsFile = sopsFile;
  };

  envLines =
    [
      "${cfg.model.apiKeyEnvVar}=${config.sops.placeholder.${cfg.model.apiKeySecret}}"
      "TELEGRAM_BOT_TOKEN=${config.sops.placeholder.${cfg.telegramBotTokenSecret}}"
      "TELEGRAM_ALLOWED_USERS=${lib.concatStringsSep "," cfg.telegramAllowedUsers}"
    ]
    ++ lib.optional cfg.hindsight.enable "HINDSIGHT_MODE=local_external"
    ++ lib.optional cfg.hindsight.enable "HINDSIGHT_API_URL=${cfg.hindsight.apiUrl}"
    ++ lib.optional cfg.link.enable "API_SERVER_ENABLED=true"
    ++ lib.optional cfg.link.enable "API_SERVER_HOST=127.0.0.1"
    ++ lib.optional cfg.link.enable "API_SERVER_PORT=8642"
    ++ lib.optional cfg.link.enable "API_SERVER_KEY=${
      config.sops.placeholder.${cfg.link.apiServerKeySecret}
    }"
    ++ lib.optional (cfg.web.exaApiKeySecret != null)
    "EXA_API_KEY=${config.sops.placeholder.${cfg.web.exaApiKeySecret}}"
    ++ lib.optional (cfg.browser.enable && cfg.browser.apiKeySecret != null)
    "BROWSER_USE_API_KEY=${config.sops.placeholder.${cfg.browser.apiKeySecret}}";

  baseSettings = {
    model = {
      default = cfg.model.default;
      provider = cfg.model.provider;
      base_url = cfg.model.baseUrl;
    };
    toolsets = ["all"];
    memory =
      {
        memory_enabled = true;
        user_profile_enabled = true;
      }
      // lib.optionalAttrs cfg.hindsight.enable {
        provider = "hindsight";
      };
    terminal = {
      cwd = hermesWorkingDirectory;
    };
  };

  webSettings = lib.optionalAttrs cfg.web.enable {
    web = {
      backend = cfg.web.backend;
      search_backend = cfg.web.backend;
      extract_backend = cfg.web.backend;
    };
  };
  browserSettings = lib.optionalAttrs cfg.browser.enable {
    browser.cloud_provider = "browser-use";
  };
in {
  options.${namespace}.services.hermes = {
    enable = mkEnableOption "Hermes Agent gateway";

    link = {
      enable =
        mkEnableOption "HermesPilot Link service"
        // {
          default = true;
        };
      apiServerKeySecret = mkOption {
        type = types.str;
        default = "hermes_api_server_key";
      };
      apiServerKeySopsFile = mkOption {
        type = types.str;
        default = hostSecretsFile;
      };
    };

    telegramBotTokenSecret = mkOption {
      type = types.str;
      default = "telegram_bot_token";
    };
    telegramBotTokenSopsFile = mkOption {
      type = types.str;
      default = hostSecretsFile;
    };

    telegramAllowedUsers = mkOption {
      type = types.listOf types.str;
      default = ["6045704025"];
    };

    model = {
      provider = mkOption {
        type = types.str;
        default = "openrouter";
      };
      default = mkOption {
        type = types.str;
        default = "deepseek/deepseek-v4-flash";
      };
      baseUrl = mkOption {
        type = types.str;
        default = "https://openrouter.ai/api/v1";
      };
      apiKeySecret = mkOption {
        type = types.str;
        default = "openrouter_api_key";
      };
      apiKeyEnvVar = mkOption {
        type = types.str;
        default = "OPENROUTER_API_KEY";
      };
      apiKeySopsFile = mkOption {
        type = types.str;
        default = hostSecretsFile;
      };
    };

    hindsight = {
      enable =
        mkEnableOption "Hindsight memory provider"
        // {
          default = true;
        };
      apiUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:8888";
      };
    };

    web = {
      enable =
        mkEnableOption "Hermes web backend"
        // {
          default = true;
        };
      backend = mkOption {
        type = types.str;
        default = "exa";
      };
      exaApiKeySecret = mkOption {
        type = types.nullOr types.str;
        default = "exa_api_key";
      };
      exaApiKeySopsFile = mkOption {
        type = types.str;
        default = hostSecretsFile;
      };
    };

    browser = {
      enable =
        mkEnableOption "Hermes Browser Use backend";
      apiKeySecret = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      apiKeySopsFile = mkOption {
        type = types.str;
        default = hostSecretsFile;
      };
    };

    xurl = {
      enable =
        mkEnableOption "official X API CLI"
        // {
          default = true;
        };
      tokenSecret = mkOption {
        type = types.str;
        default = "x_bearer_token";
      };
      tokenSopsFile = mkOption {
        type = types.str;
        default = hostSecretsFile;
      };
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      (lib.optional cfg.xurl.enable pkgs.asgaard.xurl)
      ++ (lib.optional cfg.link.enable pkgs.asgaard.hermes-link);
    sops.secrets =
      secretFrom cfg.model.apiKeySopsFile cfg.model.apiKeySecret
      // secretFrom cfg.telegramBotTokenSopsFile cfg.telegramBotTokenSecret
      // lib.optionalAttrs cfg.link.enable (
        secretFrom cfg.link.apiServerKeySopsFile cfg.link.apiServerKeySecret
      )
      // lib.optionalAttrs (cfg.web.exaApiKeySecret != null) (
        secretFrom cfg.web.exaApiKeySopsFile cfg.web.exaApiKeySecret
      )
      // lib.optionalAttrs cfg.xurl.enable (secretFrom cfg.xurl.tokenSopsFile cfg.xurl.tokenSecret)
      // lib.optionalAttrs (cfg.browser.enable && cfg.browser.apiKeySecret != null) (
        secretFrom cfg.browser.apiKeySopsFile cfg.browser.apiKeySecret
      );

    sops.templates."hermes-env" = {
      content = lib.concatStringsSep "\n" envLines + "\n";
      owner = hermesUser;
      mode = "0400";
    };

    sops.templates."hermes-xurl-token" = mkIf cfg.xurl.enable {
      content = config.sops.placeholder.${cfg.xurl.tokenSecret};
      owner = hermesUser;
      mode = "0400";
    };

    system.activationScripts."hermes-xurl-skill" = lib.stringAfter ["hermes-agent-setup"] ''
      if ${lib.boolToString cfg.xurl.enable}; then
        ${pkgs.coreutils}/bin/install -d -o ${hermesUser} -g ${hermesGroup} -m 0750 ${hermesStateDir}/.hermes/skills/xurl
        ${pkgs.coreutils}/bin/install -o ${hermesUser} -g ${hermesGroup} -m 0640 ${pkgs.asgaard.xurl}/share/xurl/SKILL.md ${hermesStateDir}/.hermes/skills/xurl/SKILL.md
      else
        ${pkgs.coreutils}/bin/rm -f ${hermesStateDir}/.hermes/skills/xurl/SKILL.md
        ${pkgs.coreutils}/bin/rmdir ${hermesStateDir}/.hermes/skills/xurl 2>/dev/null || true
      fi
    '';

    services.hermes-agent = {
      enable = true;
      environmentFiles = [config.sops.templates."hermes-env".path];
      addToSystemPackages = true;
      extraPackages = lib.optional cfg.xurl.enable pkgs.asgaard.xurl;
      extraDependencyGroups = [
        "messaging"
        "hindsight"
        "exa"
      ];
      settings = lib.recursiveUpdate baseSettings (
        lib.recursiveUpdate webSettings (
          lib.recursiveUpdate browserSettings cfg.settings
        )
      );
    };

    systemd.services.hermes-agent = {
      after = ["sops-nix.service"] ++ lib.optional cfg.hindsight.enable "podman-hindsight.service";
      wants = ["sops-nix.service"] ++ lib.optional cfg.hindsight.enable "podman-hindsight.service";
      restartTriggers =
        [
          config.sops.templates."hermes-env".content
        ]
        ++ lib.optional cfg.xurl.enable config.sops.templates."hermes-xurl-token".content;
      preStart = lib.optionalString cfg.xurl.enable ''
        umask 077
        ${pkgs.coreutils}/bin/cat ${
          config.sops.templates."hermes-xurl-token".path
        } | ${pkgs.asgaard.xurl}/bin/xurl auth app-only - >/dev/null
        ${pkgs.coreutils}/bin/chmod 0600 "$HOME/.xurl"
      '';
    };

    systemd.services.hermes-link = mkIf cfg.link.enable {
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
        ExecStart = "${pkgs.asgaard.hermes-link}/bin/hermeslink daemon";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
