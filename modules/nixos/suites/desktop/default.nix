{ options, config, lib, pkgs, ... }:
with lib;
with lib.custom;
let cfg = config.suites.desktop;
in {
  options.suites.desktop = with types; {
    enable = mkBoolOpt false "Enable the desktop suite";
  };

  config = mkIf cfg.enable {
    desktop.hyprland.enable = true;
    apps.firefox.enable = true;
    # apps.discord.enable = true;

    apps.tools.gnupg.enable = true;
    # apps.pass.enable = true;

    suites.common.enable = true;

    # services.devmon.enable = true;
    # services.gvfs.enable = true;
    # services.udisks2.enable = true;

    services.gpg-agent.enable = true;
    services.flatpak.enable = true;

    services.greetd = {
      enable = true;
      settings.default_session.command =
        "${pkgs.greetd.tuigreet}/bin/tuigreet -- theme border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red --time --asterisks --remember --cmd Hyprland";
    };
    systemd.tmpfiles.rules =
      [ "d '/var/cache/tuigreet' - greeter greeter - -" ];

    environment.persist.directories = [ "/var/cache/tuigreet" ];

    # services.xserver = {
    #   enable = true;
    #   displayManager.gdm.enable = true;
    # };

    # environment.persist.directories = [
    #   "/etc/gdm"
    # ];

    environment.systemPackages = with pkgs; [ nemo xclip xarchiver ];
  };
}
