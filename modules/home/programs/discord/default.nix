{ config, lib, pkgs, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.programs.discord;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.programs.discord = {
    enable = mkEnableOption "Discord";
  };

  config = mkIf cfg.enable {
    xdg.configFile."BetterDiscord/data/stable/custom.css" = {
      source = ./custom.css;
    };
    home.packages = with pkgs; [ goofcord ];

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".config/goofcord" ];
    };
  };
}
