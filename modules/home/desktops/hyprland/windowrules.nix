{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # windowrule = [ "float, bitwarden" ];

      windowrulev2 = [
        "idleinhibit fullscreen, class:^(firefox)$"
        "idleinhibit fullscreen, class:^(brave)$"
        "float, title:^(Picture in picture)$"
        "pin, title:^(Picture in picture)$"
      ];

    };
  };
}
