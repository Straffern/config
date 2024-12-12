{ lib, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.apps.kitty;
in {
  options.${namespace}.apps.kitty = { enable = mkEnableOption "Kitty"; };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
    };
  };
}
