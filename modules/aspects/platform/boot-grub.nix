{den, ...}: {
  den.aspects.platform.boot-grub.nixos.boot = {
    initrd.systemd.enable = true;
    loader = {
      timeout = 1;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        # Each generation with a distinct kernel/initrd copies ~48 MiB onto the 512 MiB ESP.
        configurationLimit = 10;
      };
    };
  };
}
