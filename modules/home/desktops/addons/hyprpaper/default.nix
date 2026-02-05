{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.hyprpaper;
in {
  options.${namespace}.desktops.addons.hyprpaper = {
    enable = mkEnableOption "Hyprpaper config";
  };

  config = mkIf cfg.enable {
    # Lower RestartSec from HM default (10s) for faster recovery after crashes
    systemd.user.services.hyprpaper.Service.RestartSec = lib.mkForce 5;

    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2;
      };
    };
  };
}
