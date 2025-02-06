{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.bat;
in {
  options.${namespace}.cli.programs.bat = { enable = mkEnableOption "Bat"; };

  config = mkIf cfg.enable { programs.bat = { enable = true; }; };
}
