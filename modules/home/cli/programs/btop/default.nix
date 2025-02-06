{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.btop;
in {
  options.${namespace}.cli.programs.btop = { enable = mkEnableOption "btop"; };

  config = mkIf cfg.enable {
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "Default";
        theme_background = false;
      };
    };
  };
}
