{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.swaync;
in {
  options.${namespace}.desktops.addons.swaync = {
    enable = mkEnableOption "Sway notification center";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      settings = {};
      style = builtins.readFile ./swaync.css;
    };

    # Survive Hyprland crash restarts: wait for new Wayland socket before retrying
    systemd.user.services.swaync = {
      Unit = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        RestartSec = 5;
      };
    };
  };
}
