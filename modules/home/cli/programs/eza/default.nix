{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.eza;
in {
  options.${namespace}.cli.programs.eza = { enable = mkEnableOption "Eza"; };

  config = mkIf cfg.enable { programs.eza = { enable = true; }; };
}
