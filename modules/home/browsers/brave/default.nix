{ lib, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.browsers.brave;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.browsers.brave = { enable = mkEnableOption "Brave"; };

  config = mkIf cfg.enable {
    home.sessionVariables.KDE_USE_SESSION_KEYRING = "0";

    programs.brave = {
      enable = true;
      commandLineArgs = [
        "--disable-gpu-driver-bug-workaround --skia-graphite-backend"
        "--disable-features=PasswordManager"
        "--password-store=basic"
        "--no-default-browser-check"
        "--restore-last-session"
        "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks,PlatformHEVCEncoderSupport"
        "--ozone-platform=wayland"
        "--ozone-platform-hint=wayland"
      ];
    };

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".brave" ".cache/brave" ];
    };
  };
}
