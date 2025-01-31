{ lib, namespace, pkgs, ... }:
let inherit (lib.${namespace}) enabled;
in {

  imports = [ ./disks ./hardware-configuration.nix ];

  services = {
    virtualisation.kvm = enabled;
    virtualisation.podman = enabled;
  };

  # system.battery.enable =
  #   true; # Only for laptops, they will still work without it, just improves battery life
  # system.shell.shell = "zsh";
  #
  # environment.systemPackages = with pkgs; [
  #   # Any particular packages only for this host
  #   micromamba
  #   tealdeer
  #   nodejs
  # ];
  #
  # system.shell.initExtra = ''eval "$(micromamba shell hook --shell zsh)"'';
  #

  suites = {
    desktop = {
      enable = true;
      addons = { hyprland = enabled; };
    };
  };

  # impermanence.enable = true;

  # Enable Bootloader
  system.boot.efi.enable = true;

  networking.hostName = "grug";
  boot = {
    kernelParams = [ "resume_offset=533760" ];
    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "23.11";
  # ======================== DO NOT CHANGE THIS ========================
}
