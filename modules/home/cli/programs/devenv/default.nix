{ lib, pkgs, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.devenv;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.cli.programs.devenv = {
    enable = mkEnableOption "Devenv";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.devenv ];

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".config/devenv" ".local/share/devenv" ];
    };
  };
}
