{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.desktop;
in {
  options.${namespace}.suites.desktop = { enable = mkEnableOption "Desktop suite"; };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    ${namespace}.suites = {
      common = enabled;
      desktop.addons = { nautilus = enabled; };
    };

    hardware = {
      audio = enabled;
      bluetooth = enabled;
    };

    ${namespace}.system.boot.plymouth = true;

    ${namespace}.services = {
      podman = enabled;
      avahi = enabled;
      vpn = enabled;
      # backup.enable = true;
    };

    ${namespace}.cli.programs = {
      nh.enable = true;
      nix-ld = enabled;
    };

    ${namespace}.user = {
      name = "alex";
      initialPassword = "1";
    };

    # apps.firefox.enable = true;

    # apps.tools.gnupg.enable = true;

    # services.gpg-agent.enable = true;
    # services.flatpak.enable = true;

    # environment.systemPackages = with pkgs; [
    #   greetd.tuigreet
    #   nemo
    #   xclip
    #   xarchiver
    # ];
  };
}
