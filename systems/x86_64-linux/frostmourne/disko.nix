{ lib, ... }: {
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "2M";
            type = "EF02"; # BIOS boot partition
          };
          esp = {
            name = "ESP";
            size = "512M"; # Increased size for safety
            type = "EF00"; # EFI System Partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              # Add explicit FAT32 formatting
              extraArgs = [ "-F" "32" ];
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions =
                [ "defaults" "errors=remount-ro" ]; # Added safety option
            };
          };
        };
      };
    };
  };
}
