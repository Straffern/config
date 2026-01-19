{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.swaync;
in {
  options.${namespace}.desktops.addons.swaync = {
    enable = mkEnableOption "Sway notification center";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      settings = {};
      style = builtins.readFile ./swaync.css;
    };
  };
}
