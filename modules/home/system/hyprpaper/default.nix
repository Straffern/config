{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.system.hyprpaper;
in {
  options.${namespace}.system.hyprpaper = {
    enable = mkEnableOption "Hyprpaper";
  };
  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;
      };
    };
  };
}
