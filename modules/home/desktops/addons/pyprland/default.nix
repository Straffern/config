{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.pyprland;
  sessionTarget = config.wayland.systemd.target;
in {
  options.${namespace}.desktops.addons.pyprland = {
    enable = mkEnableOption "Pyprland plugins for hyprland";
  };

  config = mkIf cfg.enable {
    xdg.configFile."pypr/config.toml".source = ./pyprland.toml;

    home.packages = with pkgs; [pyprland];

    # Pyprland daemon: survive Hyprland crash restarts
    systemd.user.services.pyprland = {
      Unit = {
        Description = "Pyprland Hyprland plugins daemon";
        After = [sessionTarget];
        PartOf = [sessionTarget];
      };
      Service = {
        ExecStart = "${pkgs.pyprland}/bin/pypr";
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [sessionTarget];
    };
  };
}
