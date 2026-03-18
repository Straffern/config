# OpenViking — Context Database for AI Agents (containerised)
#
# Runs as an OCI container (podman) providing semantic memory via HTTP.
# Used by OpenClaw's memory plugin on localhost:1933.
#
# Config is a JSON file (ov.conf) — generate with sops.templates for secrets.
# Uses host networking — server binds to 127.0.0.1, reachable by OpenClaw on same host.
#
# Reference: https://github.com/volcengine/OpenViking
{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.services.openviking;
in {
  options.${namespace}.services.openviking = {
    enable = mkEnableOption "OpenViking context database for AI agents";

    imageTag = mkOpt types.str "v0.2.7"
      "Container image tag from ghcr.io/volcengine/openviking.";

    configFile = mkOption {
      type = types.path;
      description = ''
        Path to OpenViking JSON config file (ov.conf).
        Mounted read-only into the container at /app/ov.conf.

        Paths inside the config are interpreted by the container process —
        use relative paths (e.g. ./data) or container-absolute paths (/app/data),
        NOT host paths.

        Use sops.templates to generate with embedded secrets:
          sops.templates."openviking-config" = {
            content = builtins.toJSON { ... };
          };
      '';
    };

    dataDir = mkOpt types.str "/var/lib/openviking"
      "Host directory for persistent state (vector DB, sessions). Mounted to /app/data in container.";
  };

  config = mkIf cfg.enable {
    # Container runtime + persistence
    ${namespace} = {
      services.virtualisation.podman.enable = true;
      system.impermanence.directories = [cfg.dataDir];
    };

    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers.openviking = {
      image = "ghcr.io/volcengine/openviking:${cfg.imageTag}";

      volumes = [
        "${cfg.configFile}:/app/ov.conf:ro"
        "${cfg.dataDir}/data:/app/data"
      ];

      # Host networking — no port mapping needed, server binds to 127.0.0.1 directly.
      # Avoids OpenViking's security check that requires root_api_key on 0.0.0.0.
      extraOptions = ["--network=host"];
    };

    # Ensure data directory exists on host
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 root root -"
      "d ${cfg.dataDir}/data 0750 root root -"
    ];
  };
}
