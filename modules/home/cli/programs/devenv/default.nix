{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.devenv;
in {
  options.${namespace}.cli.programs.devenv = {
    enable = mkEnableOption "Devenv";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.devenv];

    ${namespace}.system.persistence.directories = [".config/devenv" ".local/share/devenv"];
  };
}
