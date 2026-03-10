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

    # Disable Stylix's hyprpaper target — it injects old-format preload/wallpaper
    # entries incompatible with hyprpaper main branch's hyprlang block syntax
    stylix.targets.hyprpaper.enable = lib.mkForce false;

    services.hyprpaper = {
      enable = true;
      # hyprlang requires monitor as first key in wallpaper block;
      # Nix attrsets sort alphabetically, so force monitor to top
      importantPrefixes = ["$" "monitor"];
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2;
        wallpaper = [
          {
            monitor = "*";
            path = toString config.stylix.image;
          }
        ];
      };
    };
  };
}
