{ config, pkgs, lib, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.suites.gaming;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.suites.gaming = {
    enable = mkEnableOption "Gaming suite";
  };

  config = mkIf cfg.enable {
    programs.mangohud = {
      enable = true;
      enableSessionWide = true;
      settings = { cpu_load_change = true; };
    };

    home.packages = with pkgs; [ lutris bottles ];

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".steam" ".local/share/Steam" ];
    };
  };
}
