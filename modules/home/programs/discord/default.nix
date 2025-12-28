{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.programs.discord;
in {
  options.${namespace}.programs.discord = {
    enable = mkEnableOption "Discord";
  };

  config = mkIf cfg.enable {
    xdg.configFile."BetterDiscord/data/stable/custom.css" = {
      source = ./custom.css;
    };
    home.packages = with pkgs; [ goofcord ];

    ${namespace}.system.persistence.directories = [ ".config/goofcord" ];
  };
}
