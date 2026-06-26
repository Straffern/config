{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.hindsight;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.${namespace}.services.hindsight = {
    enable = mkEnableOption "Hindsight memory service";
  };

  config = mkIf cfg.enable {
    sops.secrets.groq_api_key = {
      sopsFile = ../../../../secrets.yaml;
    };

    sops.templates."hindsight-env" = {
      content = ''
        HINDSIGHT_API_LLM_PROVIDER=groq
        HINDSIGHT_API_LLM_API_KEY=${config.sops.placeholder."groq_api_key"}
        HINDSIGHT_API_LLM_MODEL=openai/gpt-oss-120b
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
