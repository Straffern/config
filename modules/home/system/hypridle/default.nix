{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.system.hypridle;
in {
  options.${namespace}.system.hypridle = {
    enable = mkEnableOption "hypridle";
  };
  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {

        general = {
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 600;
            on-timeout = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
          }
          {
            timeout = 600;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
