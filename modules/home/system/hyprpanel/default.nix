{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.system.hyprpanel;

in {
  options.${namespace}.system.hyprpanel = {
    enable = mkEnableOption "hyprpanel";
  };
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.exec-once =
      [ "${pkgs.hyprpanel}/bin/hyprpanel" ];

    home.packages = with pkgs; [ hyprpanel libnotify ];

  };
}
