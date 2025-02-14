{ options, config, lib, pkgs, namespace, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.xdg-portal;

in {
  options.${namespace}.desktops.addons.xdg-portal = {
    enable = mkEnableOption "Xdg-portal hyprland & gtk";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
          # INFO: this might only work for NixOS
          xdg-desktop-portal-wlr
        ];
      };
    };
  };
}
