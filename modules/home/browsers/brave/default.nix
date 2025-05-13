{ lib, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  # inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.browsers.brave;
in {
  options.${namespace}.browsers.brave = { enable = mkEnableOption "Brave"; };

  config = mkIf cfg.enable {

    home.sessionVariables.KDE_USE_SESSION_KEYRING = "0";

    programs.brave = {
      enable = true;
      commandLineArgs = [
        "--disable-features=PasswordManager"
        "--password-store=basic"
        "--no-default-browser-check"
        "--restore-last-session"
        "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    };
    home.persistence."/persist/home/${config.home.username}".directories =
      [ ".brave" ".cache/brave" ];
  };
}
