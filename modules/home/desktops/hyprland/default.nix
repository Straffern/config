{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.hyprland;
in {
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.desktops.hyprland = with lib.type; {
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

    desktops.addons = {
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
