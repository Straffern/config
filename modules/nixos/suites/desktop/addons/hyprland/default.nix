{ config, lib, namespace, ... }:
let
  cfg = config.${namespace}.suites.desktop.addons.hyprland;
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
in {
  options.${namespace}.suites.desktop.addons.hyprland = {
    enable = mkEnableOption "Hyprland";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    ${namespace}.suites.desktop.addons.tuigreet = enabled;
  };
}
