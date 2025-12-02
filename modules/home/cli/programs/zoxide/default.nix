{ config, lib, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.zoxide;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.cli.programs.zoxide = {
    enable = mkEnableOption "Zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".local/share/zoxide" ];
    };
  };
}
