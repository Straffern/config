{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.zoxide;
in {
  options.${namespace}.cli.programs.zoxide = {
    enable = mkEnableOption "Zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    ${namespace}.system.persistence.directories = [ ".local/share/zoxide" ];
  };
}
