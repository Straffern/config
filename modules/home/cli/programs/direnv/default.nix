{ lib, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.cli.programs.direnv;
in {
  options.${namespace}.cli.programs.direnv = {
    enable = mkEnableOption "Direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv = enabled;
    };
    home.sessionVariables.DIRENV_LOG_FORMAT = ""; # Blank so direnv will shut up
    home.persistence."/persist".users.${config.home.username}.directories =
      [ ".local/share/direnv" ];
  };
}
