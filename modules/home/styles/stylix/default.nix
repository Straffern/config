{ lib, pkgs, config, namespace, inputs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.styles.stylix;
in {
  imports = with inputs; [ stylix.homeManagerModules.stylix ];
  options.${namespace}.styles.stylix = { enable = mkEnableOption "Stylix"; };
  config = mkIf cfg.enable {

  };
}
