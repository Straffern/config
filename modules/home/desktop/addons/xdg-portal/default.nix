{ options, config, lib, pkgs, namespace, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktop.addons.xdg-portal;

in {
  options.${namespace}.desktop.addons.xdg-portal = {
    enable = mkEnableOption "Xdg-portal hyprland & gtk";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };
    };
  };
}
