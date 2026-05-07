{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionalString;
  cfg = config.${namespace}.cli.programs.devenv;
in {
  options.${namespace}.cli.programs.devenv = {
    enable = mkEnableOption "Devenv";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.devenv];

    ${namespace} = {
      cli.shells.zsh.initContent = optionalString config.${namespace}.cli.shells.zsh.enable ''
        eval "$(devenv hook zsh)"
      '';

      system.persistence.directories = [
        ".config/devenv"
        ".local/share/devenv"
      ];
    };
  };
}
