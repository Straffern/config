{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.desktop;
in {
  options.${namespace}.suites.desktop = {
    enable = mkEnableOption "Desktop suite";
  };

  config = mkIf cfg.enable {
    # System-level configurations
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Namespace-specific configurations
    ${namespace} = {
      hardware = {
        audio = enabled;
        bluetoothctl = enabled;
      };
      suites = {
        common = enabled;
        desktop.addons = { nautilus = enabled; };
      };
      system.boot.plymouth = true;

      services = {
        avahi = enabled;
        vpn = enabled;
        virtualisation.podman = enabled;
        ydotool = enabled;
      };

      cli.programs = {
        nh = enabled;
        nix-ld = enabled;
      };

    };

    environment.systemPackages = with pkgs; [ libnotify ];
  };
}
