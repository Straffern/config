{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.qt;
in {
  options.${namespace}.desktops.addons.qt = {
    enable = mkEnableOption "QT theme management";
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "gtk2";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
