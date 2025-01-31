{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.suites.desktop;
in {
  options.suites.desktop = { enable = mkEnableOption "Desktop suite"; };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    suites = {
      common = enabled;
      desktop.addons = { nautilus = enabled; };
    };

    hardware = {
      audio = enabled;
      bluetooth = enabled;
    };

    system.boot.plymouth = true;

    services = {
      podman = enabled;
      ${namespace}.avahi = enabled;
      vpn = enabled;
      # backup.enable = true;
    };

    cli.programs = {
      nh.enable = true;
      nix-ld = enabled;
    };

    user = {
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
