{ lib, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.cli.programs.direnv;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
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

    home.file.".config/direnv/direnv.toml".text = ''
      [global]
      log_format = "-"
      log_filter = "^$"
    '';

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".local/share/direnv" ];
    };
  };
}
