# Tofi is a dmeny-like application launcher
{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.system.tofi;
  background = "#${config.lib.stylix.colors.base00}70";
  accent = "#${config.lib.stylix.colors.base0D}";
in {
  options.${namespace}.system.tofi = { enable = mkEnableOption "Tofi"; };
  config = mkIf cfg.enable {
    programs.tofi = {
      enable = true;
      settings = {
        border-width = 0;
        background-color = background;
        prompt-color = accent;
        selection-color = accent;
        height = "100%";
        num-results = 5;
        outline-width = 0;
        padding-left = "35%";
        padding-top = "35%";
        result-spacing = 25;
        width = "100%";
      };
    };
  };
}
