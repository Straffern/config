{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.tools.devenv;
in {
  options.${namespace}.tools.devenv = { enable = mkEnableOption "Devenv"; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.devenv ];
    home.persist.directories = [ ".config/devenv" ".local/share/devenv" ];
  };
}
