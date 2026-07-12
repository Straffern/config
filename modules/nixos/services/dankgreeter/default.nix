{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.services.dankgreeter;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.${namespace}) mkOpt;
in
{
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
    # DMS upstream creates this tree, but nixpkgs module currently omits it.
    # Keep until dms-greeter tmpfiles setup includes WirePlumber state.
    systemd.tmpfiles.rules = [
      "d /var/lib/dms-greeter/.local 0750 dms-greeter dms-greeter -"
      "d /var/lib/dms-greeter/.local/state 0750 dms-greeter dms-greeter -"
      "d /var/lib/dms-greeter/.local/state/wireplumber 0750 dms-greeter dms-greeter -"
    ];
    # nixpkgs' DMS greeter module handles greetd enable + command, tmpfiles,
    # dedicated dms-greeter user/group, fonts, PAM stub, libinput, and graphics.
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = cfg.compositor;
      package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
    }
    // lib.optionalAttrs (cfg.configHome != null) {
      inherit (cfg) configHome;
    };

    services.fprintd.enable = true;
    # Lock screen password uses login PAM; DMS runs fingerprint separately.
    security.pam.services.login.fprintAuth = false;
    security.pam.services = {
      greetd = {
        fprintAuth = true;
        rules.auth.fprintd.settings = {
          "max-tries" = "1";
          timeout = "5";
        };
      };
      dms-greeter = {
        fprintAuth = true;
        rules.auth.fprintd.settings = {
          "max-tries" = "1";
          timeout = "5";
        };
      };
    };

    environment.systemPackages = [ pkgs.fprintd ];

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
