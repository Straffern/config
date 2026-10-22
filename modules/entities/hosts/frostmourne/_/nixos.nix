{lib, ...}: {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    # Each generation with a distinct kernel/initrd copies ~48 MiB onto the 512 MiB ESP.
    configurationLimit = 10;
  };
}
