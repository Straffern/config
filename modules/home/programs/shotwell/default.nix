{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.programs.shotwell;
in {
  options.${namespace}.programs.shotwell = {
    enable = mkEnableOption "Shotwell";
  };

  config = mkIf cfg.enable {home.packages = with pkgs; [shotwell];};
}
