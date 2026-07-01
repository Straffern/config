{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.hermes;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  secret = name: {
    ${name} = {
      sopsFile = ../../../../secrets.yaml;
    };
  };

  envLines = [
    "OPENAI_API_KEY=${config.sops.placeholder.${cfg.aiApiKeySecret}}"
    "TELEGRAM_BOT_TOKEN=${config.sops.placeholder.${cfg.telegramBotTokenSecret}}"
    "TELEGRAM_ALLOWED_USERS=${lib.concatStringsSep "," cfg.telegramAllowedUsers}"
  ]
  ++ lib.optional (cfg.hindsight.enable) "HINDSIGHT_MODE=local_external"
  ++ lib.optional (cfg.hindsight.enable) "HINDSIGHT_API_URL=${cfg.hindsight.apiUrl}"
  ++
    lib.optional (cfg.web.exaApiKeySecret != null)
      "EXA_API_KEY=${config.sops.placeholder.${cfg.web.exaApiKeySecret}}"
  ++
    lib.optional (cfg.xSearch.xaiApiKeySecret != null)
      "XAI_API_KEY=${config.sops.placeholder.${cfg.xSearch.xaiApiKeySecret}}";

  baseSettings = {
    model = {
      default = cfg.model.default;
      provider = cfg.model.provider;
      base_url = cfg.model.baseUrl;
    };
    toolsets = [ "all" ];
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
    }
    // lib.optionalAttrs cfg.hindsight.enable {
      provider = "hindsight";
    };
  };

  webSettings = lib.optionalAttrs cfg.web.enable {
    web = {
      backend = cfg.web.backend;
      search_backend = cfg.web.backend;
      extract_backend = cfg.web.backend;
    };
  };

  xSearchSettings = lib.optionalAttrs cfg.xSearch.enable {
    x_search = {
      model = cfg.xSearch.model;
      timeout_seconds = cfg.xSearch.timeoutSeconds;
      retries = cfg.xSearch.retries;
    };
  };
in
{
  options.${namespace}.services.hermes = {
    enable = mkEnableOption "Hermes Agent gateway";

    aiApiKeySecret = mkOption {
      type = types.str;
      default = "openclaw_ai_api_key";
    };

    telegramBotTokenSecret = mkOption {
      type = types.str;
      default = "hermes_telegram_bot_token";
    };

    telegramAllowedUsers = mkOption {
      type = types.listOf types.str;
      default = [ "6045704025" ];
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
    };

    hindsight = {
      enable = mkEnableOption "Hindsight memory provider" // {
        default = true;
      };
      apiUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:8888";
      };
    };

    web = {
      enable = mkEnableOption "Hermes web backend" // {
        default = true;
      };
      backend = mkOption {
        type = types.str;
        default = "exa";
      };
      exaApiKeySecret = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };

    xSearch = {
      enable = mkEnableOption "Hermes X Search";
      xaiApiKeySecret = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      model = mkOption {
        type = types.str;
        default = "grok-4.20-reasoning";
      };
      timeoutSeconds = mkOption {
        type = types.int;
        default = 180;
      };
      retries = mkOption {
        type = types.int;
        default = 2;
      };
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets =
      secret cfg.aiApiKeySecret
      // secret cfg.telegramBotTokenSecret
      // lib.optionalAttrs (cfg.web.exaApiKeySecret != null) (secret cfg.web.exaApiKeySecret)
      // lib.optionalAttrs (cfg.xSearch.xaiApiKeySecret != null) (secret cfg.xSearch.xaiApiKeySecret);

    sops.templates."hermes-env" = {
      content = lib.concatStringsSep "\n" envLines + "\n";
      owner = "hermes";
      mode = "0400";
    };

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environmentFiles = [ config.sops.templates."hermes-env".path ];
      extraDependencyGroups = [
        "messaging"
        "hindsight"
        "exa"
      ];
      settings = lib.recursiveUpdate (lib.recursiveUpdate baseSettings webSettings) (
        lib.recursiveUpdate xSearchSettings cfg.settings
      );
    };

    systemd.services.hermes-agent = {
      after = [
        "sops-nix.service"
      ]
      ++ lib.optional cfg.hindsight.enable "podman-hindsight.service";
      wants = [
        "sops-nix.service"
      ]
      ++ lib.optional cfg.hindsight.enable "podman-hindsight.service";
      restartTriggers = [ config.sops.templates."hermes-env".content ];
    };
  };
}
