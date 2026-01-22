{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.suites.gamedev;
in {
  options.${namespace}.suites.gamedev = {
    enable = mkEnableOption "Game dev suite";
  };

  config = mkIf cfg.enable {home.packages = with pkgs; [godot_4 aseprite];};
}
