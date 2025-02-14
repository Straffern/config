{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.devenv;
in {
  options.${namespace}.cli.programs.devenv = {
    enable = mkEnableOption "Devenv";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.devenv ];
    home.persistence."/persist/home/${config.home.username}" = {
      directories = [ ".config/devenv" ".local/share/devenv" ];
      allowOther = true;
    };
  };
}
