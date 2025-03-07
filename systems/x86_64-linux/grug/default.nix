{ lib, namespace, pkgs, ... }:
let inherit (lib.${namespace}) enabled;
in {

  imports = [ ./hardware-configuration.nix ];

  home-manager.backupFileExtension = "backup";

  ${namespace} = {
    system.boot = enabled;

    user = {
      "1" = {
        name = "alex";
        initialHashedPassword =
          "$6$5aPLuGMVlK2YIt5x$Ia4aC72iA6EDPcnB06B7RWtci9LVK8.aTK1APcUfAKRhlVweSCy0GT3IguQ/6D2Cv2v1M/iNORUoz6Hkbsh3J/";
        extraGroups = [ "wheel" ];
      };
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

  networking.hostName = "grug";
  boot = {
    # kernelParams = [ "resume_offset=533760" ];
    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    # resumeDevice = "/dev/disk/by-label/nixos";
  };

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "23.11";
  # ======================== DO NOT CHANGE THIS ========================
}
