{ options, config, lib, pkgs, namespace, ... }:
with lib;
with lib.custom;
let cfg = config.suites.common;
in {
  options.suites.common = with types; {
    enable = mkBoolOpt false "Enable the common suite";
  };

  config = mkIf cfg.enable {
    system.nix.enable = true;
    system.security.doas.enable = true;

    hardware.audio.enable = true;
    hardware.networking.enable = true;

    apps.misc.enable = true;

    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings = {
      General = {
        FastConnectable = true;
        JustWorksRepairing = "always";
        Privacy = "device";
      };
      Policy = { AutoEnable = true; };
      inputs = { UserSpaceHID = true; };
    };

    environment.persist.directories =
      mkIf config.impermanence.enable [ "/var/lib/bluetooth" ];

    apps.tools.git.enable = true;
    apps.tools.nix-ld.enable = true;

    services.ssh.enable = false;
    programs.dconf.enable = true;

    environment.systemPackages = [ pkgs.bluetuith pkgs.custom.sys ];

    environment.sessionVariables.NIXOS_OZONE_WL = mkIf snowfallorg.users.${
        config.${namespace}.user.name
      }.home.config.desktop.hyprland.enable
      "1"; # Hint electron apps to use wayland

    system = {
      fonts.enable = true;
      locale.enable = true;
      time.enable = true;
      xkb.enable = true;
    };
  };
}
