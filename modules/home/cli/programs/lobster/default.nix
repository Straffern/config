{ inputs, pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.lobster;
in {
  options.${namespace}.cli.programs.lobster = {
    enable = mkEnableOption "lobster";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.lobster.packages.${pkgs.system}.default ];
  };
}
