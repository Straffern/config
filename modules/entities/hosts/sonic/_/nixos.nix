{
  lib,
  pkgs,
  ...
}: {
  environment.variables.EDITOR = "nvim";
  users.mutableUsers = false;
  users.users.alex = {
    initialHashedPassword = "$6$Xzsm8xWpuEtAOgfe$TMvP8XkkM2UHUSCANLq0CSzmsTVWRDaZNsDn1VlOUQ9WmJUROQYbFkQqHDXmqJ5NYTZn2KY3e/LhmgPQA204z1";
    uid = 1000;
  };

  services.fwupd.enable = true;
  services.gnome.at-spi2-core.enable = true;
  services.journald.extraConfig = "SystemMaxUse=500M";
  networking = {
    useNetworkd = false;
    firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
  boot = {
    kernelParams = ["resume_offset=533760"];
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_zen;
    kernel.sysctl = {
      "vm.dirty_background_bytes" = 268435456;
      "vm.dirty_bytes" = 1073741824;
      "vm.dirty_background_ratio" = lib.mkForce 0;
      "vm.dirty_ratio" = lib.mkForce 0;
      "vm.dirty_writeback_centisecs" = 500;
    };
    resumeDevice = "/dev/disk/by-label/nixos";
  };
}
