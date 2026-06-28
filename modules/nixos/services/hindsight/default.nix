{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.hindsight;
  inherit (lib) mkEnableOption mkIf;
  routerConfig = builtins.toJSON {
    model_list = [
      {
        model_name = "default";
        litellm_params = {
          model = "groq/openai/gpt-oss-20b";
          api_key = config.sops.placeholder."groq_api_key";
        };
      }
      {
        model_name = "groq-openai-gpt-oss-120b";
        litellm_params = {
          model = "groq/openai/gpt-oss-120b";
          api_key = config.sops.placeholder."groq_api_key";
        };
      }
      {
        model_name = "openrouter-deepseek-v4-flash";
        litellm_params = {
          model = "openrouter/deepseek/deepseek-v4-flash";
          api_key = config.sops.placeholder."openrouter_api_key";
          extra_body = {
            provider = {
              require_parameters = true;
            };
          };
        };
      }
    ];
    fallbacks = [
      {
        default = [
          "groq-openai-gpt-oss-120b"
          "openrouter-deepseek-v4-flash"
        ];
      }
    ];
    num_retries = 0;
    max_fallbacks = 2;
    cooldown_time = 5;
  };
in
{
  options.${namespace}.services.hindsight = {
    enable = mkEnableOption "Hindsight memory service";
  };

  config = mkIf cfg.enable {
    sops.secrets.groq_api_key = {
      sopsFile = ../../../../secrets.yaml;
    };
    sops.secrets.openrouter_api_key = {
      sopsFile = ../../../../secrets.yaml;
    };

    sops.templates."hindsight-env" = {
      content = ''
        HINDSIGHT_API_LLM_PROVIDER=litellmrouter
        HINDSIGHT_API_LLM_LITELLMROUTER_CONFIG=${routerConfig}
        HINDSIGHT_API_WORKER_ID=hindsight-sonic
      '';
      owner = "root";
      mode = "0400";
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.hindsight = {
        image = "ghcr.io/vectorize-io/hindsight:latest";
        autoStart = true;
        ports = [
          "127.0.0.1:8888:8888"
          "127.0.0.1:9999:9999"
        ];
        environmentFiles = [ config.sops.templates."hindsight-env".path ];
        volumes = [ "/var/lib/hindsight/pg0:/home/hindsight/.pg0" ];
        extraOptions = [ "--pull=always" ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/hindsight 0750 1000 1000 -"
      "d /var/lib/hindsight/pg0 0750 1000 1000 -"
    ];

    systemd.services.podman-hindsight = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      restartTriggers = [ config.sops.templates."hindsight-env".content ];
    };

    ${namespace}.system.impermanence.directories = [ "/var/lib/hindsight" ];
  };
}
