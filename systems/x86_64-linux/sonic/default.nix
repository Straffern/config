{ lib, namespace, pkgs, inputs, ... }:
let inherit (lib.${namespace}) enabled;
in {

  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
  ];

  ${namespace} = {
    system.env = { EDITOR = "nvim"; };

    user."1" = {
      name = "alex";
      initialHashedPassword =
        "$6$Xzsm8xWpuEtAOgfe$TMvP8XkkM2UHUSCANLq0CSzmsTVWRDaZNsDn1VlOUQ9WmJUROQYbFkQqHDXmqJ5NYTZn2KY3e/LhmgPQA204z1";
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

  networking.hostName = "sonic";
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
