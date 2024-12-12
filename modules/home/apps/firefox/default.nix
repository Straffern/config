{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.apps.firefox;
in {
  options.${namespace}.apps.firefox = { enable = mkEnableOption "Firefox"; };

  config = mkIf cfg.enable {
    programs.librewolf = enabled;
    home.persist.directories = [ ".librewolf" ".cache/librewolf" ];
  };
}
