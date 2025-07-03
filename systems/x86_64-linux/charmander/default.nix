{ lib, namespace, pkgs, inputs, ... }:
let inherit (lib.${namespace}) enabled;
in {

  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    # inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
  ];

  ${namespace} = {
    system.env = { EDITOR = "nvim"; };

    user."1" = {
      name = "gunniko";
      extraGroups = [ "wheel" ];
      extraOptions = { uid = 1000; };
    };

    suites = {
      desktop = {
        enable = true;
        addons = { hyprland = enabled; };
      };
    };

    services = {
      virtualisation.kvm = enabled;
      virtualisation.podman = enabled;
    };
  };

  services.fwupd.enable = true;
  networking.useNetworkd = false;
  networking.firewall = {
    allowedTCPPortRanges = [{
      from = 1714;
      to = 1764;
    }];
    allowedUDPPortRanges = [{
      from = 1714;
      to = 1764;
    }];
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

  # impermanence.enable = true;

  networking.hostName = "charmander";
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
