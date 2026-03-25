{
  config,
  lib,
  namespace,
  ...
}: let
  cfg = config.${namespace}.services.dankgreeter;
  inherit (lib) mkIf mkEnableOption mkOption types;
  inherit (lib.${namespace}) mkOpt;
in {
  options.${namespace}.services.dankgreeter = {
    enable = mkEnableOption "DankGreeter login manager";
    compositor = mkOpt types.str "niri" "Compositor used to render the greeter UI";
    configHome = mkOption {
      type = types.nullOr types.str;
      default = "/home/${config.${namespace}.user."1".name}";
      description = "User home path to sync DMS theme with greeter";
    };
  };

  config = mkIf cfg.enable {

    # DMS greeter module handles greetd enable + command + tmpfiles + fonts.
    # We only set the asgaard-level options.
    programs.dank-material-shell.greeter = {
      enable = true;
      compositor.name = cfg.compositor;
    } // lib.optionalAttrs (cfg.configHome != null) {
      inherit (cfg) configHome;
    };

    # greetd service hardening — DMS greeter does not set these.
    # Without them boot logs spam the login tty.
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    # Prevent getting stuck at shutdown (user services may linger)
    systemd = {
      settings.Manager.DefaultTimeoutStopSec = "10s";
      user.extraConfig = ''
        DefaultTimeoutStopSec=10s
      '';
    };
  };
}
