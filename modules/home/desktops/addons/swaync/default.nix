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
      settings = {
        widgets = ["title" "dnd" "notifications"];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          dnd.text = "Do Not Disturb";
          notifications.vexpand = true;
        };
      };
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
