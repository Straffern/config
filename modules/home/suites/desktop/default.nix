{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib; let
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.desktop;
in {
  options.${namespace}.suites.desktop = {
    enable = mkEnableOption "Enable desktop suite";
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      suites = {
        common = enabled;
        development = enabled;
      };
      services = {
        kdeconnect = enabled;
        spotify = enabled;
      };
      desktops.addons.xdg = enabled;
    };

    # MPRIS player priority daemon - makes playerctl target last-active player
    services.playerctld.enable = true;

    # Fixes tray icons: https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = ["graphical-session-pre.target"];
      };
    };

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      LIBSEAT_BACKEND = "logind";
    };

    # TODO: move this to somewhere
    home.packages = with pkgs; [
      mpv
      jmtpfs
      brightnessctl
      xdg-utils
      wl-clipboard
      clipse
      pamixer
      playerctl

      slurp
      sway-contrib.grimshot
      pkgs.satty
    ];
  };
}
