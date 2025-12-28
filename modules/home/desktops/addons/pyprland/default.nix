{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.pyprland;
in {
  options.${namespace}.desktops.addons.pyprland = {
    enable = mkEnableOption "Pyprland plugins for hyprland";
  };

  config = mkIf cfg.enable {
    xdg.configFile."hypr/pyprland.toml".source = config.lib.asgaard.managedSource ./pyprland.toml;

    home = { packages = with pkgs; [ pyprland ]; };
  };
}
