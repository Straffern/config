{ lib, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  # inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.browsers.brave;
in {
  options.${namespace}.browsers.brave = { enable = mkEnableOption "Firefox"; };

  config = mkIf cfg.enable {
    programs.brave = {
      enable = true;
      commandLineArgs = [
        "--no-default-browser-check"
        "--restore-last-session"
        "--enable-features=TouchpadOverscrollHistoryNavigation"
      ];
    };
    home.persistence."/persist/home/${config.home.username}".directories =
      [ ".brave" ".cache/brave" ];
  };
}
