{
  den,
  inputs,
  lib,
  ...
}: {
  den.aspects.services.hindsight.nixos = {
    config,
    host,
    pkgs,
    ...
  }: let
    hostSecretsFile = inputs.self + "/secrets/hosts/${host.name}.yaml";
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
          model_name = "openrouter-deepseek-v4-flash-0731";
          litellm_params = {
            model = "openrouter/deepseek/deepseek-v4-flash-0731";
            api_key = config.sops.placeholder."openrouter_api_key";
          };
        }
      ];
      fallbacks = [
        {
          default = [
            "openrouter-deepseek-v4-flash-0731"
            "groq-openai-gpt-oss-120b"
          ];
        }
      ];
      num_retries = 0;
      max_fallbacks = 2;
      cooldown_time = 5;
    };
    deepseekRouterConfig = builtins.toJSON {
      model_list = [
        {
          model_name = "default";
          litellm_params = {
            model = "openrouter/deepseek/deepseek-v4-flash-0731";
            api_key = config.sops.placeholder."openrouter_api_key";
          };
        }
      ];
    };
    cfg = config.services.hindsight;
  in {
    options.services.hindsight = {
      workerId = lib.mkOption {
        type = lib.types.str;
        default = "hindsight-${host.name}";
      };
      reflectTimeoutSeconds = lib.mkOption {
        type = lib.types.int;
        default = 120;
        description = "Timeout for Hindsight reflect LLM requests, in seconds.";
      };
    };
    config = lib.mkMerge [
      {
        sops.secrets.groq_api_key.sopsFile = hostSecretsFile;
        sops.secrets.openrouter_api_key.sopsFile = hostSecretsFile;
        sops.templates."hindsight-env" = {
          restartUnits = ["podman-hindsight.service"];
          content = ''
            HINDSIGHT_API_LLM_PROVIDER=litellmrouter
            HINDSIGHT_API_LLM_LITELLMROUTER_CONFIG=${routerConfig}
            HINDSIGHT_API_RETAIN_LLM_PROVIDER=litellmrouter
            HINDSIGHT_API_RETAIN_LLM_LITELLMROUTER_CONFIG=${deepseekRouterConfig}
            HINDSIGHT_API_CONSOLIDATION_LLM_PROVIDER=litellmrouter
            HINDSIGHT_API_CONSOLIDATION_LLM_LITELLMROUTER_CONFIG=${deepseekRouterConfig}
            HINDSIGHT_API_REFLECT_LLM_TIMEOUT=${toString cfg.reflectTimeoutSeconds}
            HINDSIGHT_API_WORKER_ID=${cfg.workerId}
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
            environmentFiles = [config.sops.templates."hindsight-env".path];
            volumes = ["/var/lib/hindsight/pg0:/home/hindsight/.pg0"];
            extraOptions = [
              ''--health-cmd=/app/api/.venv/bin/python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8888/health', timeout=5)"''
              "--health-interval=disable"
              "--health-retries=3"
              "--health-start-period=120s"
              "--health-timeout=10s"
              "--health-on-failure=kill"
              "--pull=always"
            ];
          };
        };
        systemd.tmpfiles.rules = [
          "d /var/lib/hindsight 0750 1000 1000 -"
          "d /var/lib/hindsight/pg0 0750 1000 1000 -"
        ];
        systemd.services.podman-hindsight.unitConfig.ConditionPathExists =
          config.sops.templates."hindsight-env".path;
        systemd.services.hindsight-healthcheck = {
          description = "Check Hindsight container health";
          after = ["podman-hindsight.service"];
          requires = ["podman-hindsight.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.podman} healthcheck run hindsight";
            SuccessExitStatus = [1];
          };
        };
        systemd.timers.hindsight-healthcheck = {
          description = "Periodically check Hindsight container health";
          wantedBy = ["podman-hindsight.service"];
          partOf = ["podman-hindsight.service"];
          after = ["podman-hindsight.service"];
          timerConfig = {
            OnActiveSec = "120s";
            OnUnitActiveSec = "30s";
          };
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        environment.persistence."/persist".directories = ["/var/lib/hindsight"];
      })
    ];
  };
}
