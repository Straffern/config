{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  # inherit (lib.${namespace})
  cfg = config.${namespace}.system.locale;
in {
  options.${namespace}.system.locale = {
    enable = mkEnableOption "Manage of locale settings.";
  };

  config = mkIf cfg.enable {
    i18n = {
      defaultLocale = lib.mkDefault "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };
    # consider: 
    # services.automatic-timezoned.enable = true;

    time.timeZone = "Europe/Copenhagen";

    # Configure keymap in X11
    services.xserver = {
      xkb.layout = "us";
      xkb.variant = "";
    };
    # Configure console keymap
    console.keyMap = "us";
  };
}
