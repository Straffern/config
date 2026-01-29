{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.pyprland;
in {
  options.${namespace}.desktops.addons.pyprland = {
    enable = mkEnableOption "Pyprland plugins for hyprland";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = ["https://hyprland-community.cachix.org"];
      trusted-public-keys = [
        "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSXnmE="
      ];
    };

    xdg.configFile."pypr/config.toml".source = ./pyprland.toml;

    home.packages = with pkgs; [pyprland];

    # Pyprland daemon: survive Hyprland crash restarts
    systemd.user.services.pyprland = {
      Unit = {
        Description = "Pyprland Hyprland plugins daemon";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        ExecStart = "${pkgs.pyprland}/bin/pypr";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
