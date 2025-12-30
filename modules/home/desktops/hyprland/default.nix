{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.desktops.hyprland;
in {
  imports = [ ./config.nix ./keybindings.nix ./windowrules.nix ];

  options.${namespace}.desktops.hyprland = with types; {
    enable = mkEnableOption "Hyprland window manager";
    execOnceExtras = mkOpt (listOf str) [ ] "Extra programs to exec once";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    ${namespace}.desktops.addons = {
      xdg-portal.enable = true;
      kanshi.enable = true;
      rofi.enable = true;
      swaync.enable = true;
      waybar.enable = true;
      wlogout.enable = true;
      wlsunset.enable = true;

      pyprland.enable = true;
      hyprpaper.enable = true;
      hyprlock.enable = true;
      hypridle.enable = true;
    };
  };
}
