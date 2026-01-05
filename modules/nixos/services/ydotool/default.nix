{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.ydotool;
in {
  options.${namespace}.services.ydotool = {
    enable = mkEnableOption "ydotool daemon";
  };

  config = mkIf cfg.enable {
    # Enable the ydotool service
    programs.ydotool.enable = true;

    # Ensure users in the 'ydotool' group can use it
    # Note: programs.ydotool.enable already handles group creation and udev rules in recent nixpkgs
  };
}
