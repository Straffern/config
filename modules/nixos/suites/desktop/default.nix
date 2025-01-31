{ config, lib, namespace, ... }:
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

    hardware = {
      audio = enabled;
      bluetooth = enabled;
    };

    # Namespace-specific configurations
    ${namespace} = {
      suites = {
        common = enabled;
        desktop.addons = { nautilus = enabled; };
      };

      system.boot.plymouth = true;

      services = {
        avahi = enabled;
        vpn = enabled;
        virtualisation.podman = enabled;
      };

      cli.programs = {
        nh = enabled;
        nix-ld = enabled;
      };

      user = {
        name = "alex";
        initialPassword = "1";
      };
    };
  };
}
