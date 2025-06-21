{ config, lib, namespace, pkgs, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  # inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.desktop.addons.gnome;
in {
  options.${namespace}.suites.desktop.addons.gnome = {
    enable = mkEnableOption "Gnome";
  };

  config = mkIf cfg.enable {
    ${namespace}.suites.desktop.addons.nautilus.enable = true;

    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [ pkgs.nautilus-open-any-terminal ];
      };
      xserver = { enable = true; };
    };

    services.udev.packages = with pkgs; [ gnome-settings-daemon ];
    programs.dconf.enable = true;
  };
}
