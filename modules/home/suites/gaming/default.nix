{ config, pkgs, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.suites.gaming;
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
  };
}
