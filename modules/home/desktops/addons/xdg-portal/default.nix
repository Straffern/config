{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
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
        config = {
          common.default = ["hyprland" "gtk"];
          hyprland = {
            default = ["hyprland" "gtk"];
            "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          };
        };
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };
    };
  };
}
