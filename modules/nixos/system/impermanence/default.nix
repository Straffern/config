{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.system.impermanence;
in {
  options.${namespace}.system.impermanence = {
    enable = mkEnableOption "Impermanence";

    removeTempFilesOlderThan = mkOption {
      type = types.int;
      default = 30;
      description = "Remove temporary files older than this many days";
    };
  };

  config = mkIf cfg.enable {
    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';

    programs.fuse.userAllowOther = true;

    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@cryptroot.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
        mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /mnt

        if [ -e /mnt/root ]; then
          mkdir -p /mnt/old_roots
          timestamp=$(date --date="@$(stat -c %Y /mnt/root)" "+%Y-%m-%d_%H:%M:%S")
          mv /mnt/root "/mnt/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
          IFS=$'\n'
          for subvol in $(btrfs subvolume list -o "$1" | cut -f9 -d' '); do
            delete_subvolume_recursively "/mnt/$subvol"
          done
          btrfs subvolume delete "$1"
        }

        find /mnt/old_roots -maxdepth 1 -mtime +${
          toString cfg.removeTempFilesOlderThan
        } -print0 | while IFS= read -r -d $'\0' old_root; do
          delete_subvolume_recursively "$old_root"
        done

        btrfs subvolume create /mnt/root
        umount /mnt
      '';
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/srv"
        "/.cache/nix/"
        "/etc/NetworkManager/system-connections"
        "/var/cache/"
        "/var/db/sudo/"
        "/var/lib/"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
