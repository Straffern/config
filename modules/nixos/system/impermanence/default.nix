{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.system.impermanence;

  # Directory type - supports both strings and attribute sets
  directoryType = types.either types.str (types.submodule {
    options = {
      directory = mkOption {
        type = types.str;
        description = "The directory path to persist.";
      };
      user = mkOption {
        type = types.str;
        default = "root";
        description = "Owner user of the directory.";
      };
      group = mkOption {
        type = types.str;
        default = "root";
        description = "Owner group of the directory.";
      };
      mode = mkOption {
        type = types.str;
        default = "0755";
        description = "Permissions mode for the directory.";
      };
    };
  });

  # File type - supports both strings and attribute sets
  fileType = types.either types.str (types.submodule {
    options = {
      file = mkOption {
        type = types.str;
        description = "The file path to persist.";
      };
      parentDirectory = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Permissions for the parent directory.";
      };
    };
  });
in {
  options.${namespace}.system.impermanence = {
    enable = mkEnableOption "Impermanence";

    removeTempFilesOlderThan = mkOption {
      type = types.int;
      default = 30;
      description = "Remove temporary files older than this many days";
    };

    persistEntireVarLib = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Persist all of /var/lib instead of explicit per-service directories.
        Simpler but less declarative. Useful during migration or for catch-all setups.
      '';
    };

    directories = mkOption {
      type = types.listOf directoryType;
      default = [];
      description = "Additional system directories to persist.";
    };

    files = mkOption {
      type = types.listOf fileType;
      default = [];
      description = "Additional system files to persist.";
    };
  };

  config = mkIf cfg.enable {
    programs.persist-retro.enable = true;

    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';

    programs.fuse.userAllowOther = true;

    # boot.initrd.systemd.services.rollback = {
    #   description = "Rollback BTRFS root subvolume to a pristine state";
    #   wantedBy = [ "initrd.target" ];
    #   after = [ "systemd-cryptsetup@cryptroot.service" ];
    #   before = [ "sysroot.mount" ];
    #   unitConfig.DefaultDependencies = "no";
    #   serviceConfig.Type = "oneshot";
    #   script = ''
    #     mkdir -p /mnt
    #     mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /mnt
    #
    #     if [ -e /mnt/root ]; then
    #       mkdir -p /mnt/old_roots
    #       timestamp=$(date --date="@$(stat -c %Y /mnt/root)" "+%Y-%m-%d_%H:%M:%S")
    #       mv /mnt/root "/mnt/old_roots/$timestamp"
    #     fi
    #
    #     delete_subvolume_recursively() {
    #       IFS=$'\n'
    #       for subvol in $(btrfs subvolume list -o "$1" | cut -f9 -d' '); do
    #         delete_subvolume_recursively "/mnt/$subvol"
    #       done
    #       btrfs subvolume delete "$1"
    #     }
    #
    #     find /mnt/old_roots -maxdepth 1 -mtime +${
    #       toString cfg.removeTempFilesOlderThan
    #     } -print0 | while IFS= read -r -d $'\0' old_root; do
    #       delete_subvolume_recursively "$old_root"
    #     done
    #
    #     btrfs subvolume create /mnt/root
    #     umount /mnt
    #   '';
    # };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories =
        [
          # Base system directories (always needed)
          "/srv"
          "/.cache/nix"
          "/etc/NetworkManager/system-connections"
          "/var/cache"
          "/var/db/sudo"
        ]
        # Either persist all of /var/lib or just essential base directories
        ++ (
          if cfg.persistEntireVarLib
          then ["/var/lib"]
          else [
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
          ]
        )
        # Additional directories from other modules
        ++ cfg.directories;

      files =
        [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ]
        ++ cfg.files;
    };

    systemd.tmpfiles.rules =
      ["d! /persist/home 0770 root users - -"]
      ++ (lib.mapAttrsToList
        (_: user: "d /persist/home/${user.name} 0700 ${user.name} users - -")
        (lib.filterAttrs (_: user: user.enable) config.${namespace}.user));
  };
}
