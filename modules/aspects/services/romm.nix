{
  den,
  inputs,
  lib,
  ...
}: {
  den.aspects.services.romm = {
    includes = [
      den.aspects.services.tailscale
      den.aspects.virtualization.podman
    ];
    vmSmoke = [
      {
        name = "romm-tailscale-funnel-skipped";
        description = "RomM Funnel stays off without Tailscale identity";
        phase = "boot";
        module = {lib, ...}: {
          systemd.services.romm-tailscale-funnel.wantedBy = lib.mkForce [];
        };
      }
    ];
    nixos = {
      config,
      host,
      pkgs,
      ...
    }: let
      hostSecretsFile = inputs.self + "/secrets/hosts/${host.name}.yaml";
      ph = config.sops.placeholder;
      podman = lib.getExe pkgs.podman;
      tailscale = lib.getExe config.services.tailscale.package;
      funnelPort = 10000;
    in
      lib.mkMerge [
        {
          sops.secrets = lib.genAttrs ["romm_auth_secret_key" "romm_db_password" "romm_db_root_password"] (_: {
            sopsFile = hostSecretsFile;
          });
          sops.templates."romm-env" = {
            restartUnits = ["podman-romm.service"];
            content = ''
              ROMM_AUTH_SECRET_KEY=${ph.romm_auth_secret_key}
              DB_PASSWD=${ph.romm_db_password}
            '';
          };
          sops.templates."romm-db-env" = {
            restartUnits = ["podman-romm-db.service"];
            content = ''
              MARIADB_ROOT_PASSWORD=${ph.romm_db_root_password}
              MARIADB_PASSWORD=${ph.romm_db_password}
            '';
          };

          virtualisation.oci-containers.containers = {
            romm-db = {
              image = "docker.io/library/mariadb:11";
              networks = ["romm"];
              environment = {
                MARIADB_DATABASE = "romm";
                MARIADB_USER = "romm";
              };
              environmentFiles = [config.sops.templates."romm-db-env".path];
              volumes = ["/var/lib/romm/mysql:/var/lib/mysql"];
            };
            romm = {
              image = "docker.io/rommapp/romm:5.4.0";
              networks = ["romm"];
              dependsOn = ["romm-db"];
              ports = ["127.0.0.1:8080:8080"];
              environment = {
                ROMM_BASE_URL = "https://${host.name}.tail3cc997.ts.net:${toString funnelPort}";
                ROMM_SESSION_SECURE_COOKIE = "true";
                DB_HOST = "romm-db";
                DB_NAME = "romm";
                DB_USER = "romm";
                HASHEOUS_API_ENABLED = "true";
                LAUNCHBOX_API_ENABLED = "true";
                PLAYMATCH_API_ENABLED = "true";
                ENABLE_RESCAN_ON_FILESYSTEM_CHANGE = "true";
                RESCAN_ON_FILESYSTEM_CHANGE_DELAY = "1";
              };
              environmentFiles = [config.sops.templates."romm-env".path];
              volumes = [
                "/var/lib/romm/library:/romm/library"
                "/var/lib/romm/assets:/romm/assets"
                "/var/lib/romm/resources:/romm/resources"
                "/var/lib/romm/config:/romm/config"
                "/var/lib/romm/redis:/redis-data"
              ];
            };
          };

          systemd.services = {
            romm-network = {
              description = "Podman network for RomM";
              wantedBy = ["multi-user.target"];
              before = ["podman-romm.service" "podman-romm-db.service"];
              requiredBy = ["podman-romm.service" "podman-romm-db.service"];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${pkgs.bash}/bin/sh -c '${podman} network exists romm || ${podman} network create romm'";
              };
            };
            podman-romm.unitConfig.ConditionPathExists = config.sops.templates."romm-env".path;
            podman-romm-db.unitConfig.ConditionPathExists = config.sops.templates."romm-db-env".path;
            romm-tailscale-funnel = {
              description = "Expose RomM publicly through Tailscale Funnel";
              wantedBy = ["multi-user.target"];
              after = ["tailscaled.service" "network-online.target" "podman-romm.service"];
              wants = ["tailscaled.service" "network-online.target" "podman-romm.service"];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${tailscale} funnel --yes --bg --https=${toString funnelPort} http://127.0.0.1:8080";
                ExecStop = "${tailscale} funnel --yes --https=${toString funnelPort} off";
                Restart = "on-failure";
                RestartSec = "15s";
              };
            };
          };

          # Container uid/gid 1000 owns the app dirs; on Palantir that uid is alex, so ROMs can be rsynced straight in.
          systemd.tmpfiles.rules =
            map (d: "d /var/lib/romm/${d} 0775 1000 1000 -") ["library" "library/roms" "library/bios" "assets" "resources" "config" "redis"]
            ++ ["d /var/lib/romm/mysql 0750 - - -"];
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          environment.persistence."/persist".directories = ["/var/lib/romm"];
        })
      ];
  };
}
