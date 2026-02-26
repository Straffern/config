{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.tray-services;
in {
  options.${namespace}.desktops.addons.tray-services = {
    enable = mkEnableOption "systemd-managed tray and background services";
  };

  config = mkIf cfg.enable {
    # Suppress duplicate XDG autostart: blueman-applet is managed by systemd.
    xdg.configFile."autostart/blueman.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';

    services = {
      polkit-gnome.enable = true;
      network-manager-applet.enable = true;
      blueman-applet.enable = true;
      trayscale.enable = true;
    };

    systemd.user.services = {
      polkit-gnome.Service = {
        Restart = "on-failure";
        RestartSec = 5;
      };

      network-manager-applet.Service = {
        Restart = "on-failure";
        RestartSec = 5;
      };

      blueman-applet.Service = {
        Restart = "on-failure";
        RestartSec = 5;
      };

      trayscale.Service = {
        TimeoutStopSec = 5;
        ExecStop = "${pkgs.systemdMinimal}/bin/busctl --user call dev.deedles.Trayscale /dev/deedles/Trayscale org.gtk.Actions Activate sava{sv} quit 0 0";
        Restart = "on-failure";
        RestartSec = 5;
      };

      clipse = {
        Unit = {
          Description = "Clipse listener";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          ExecStart = "${pkgs.clipse}/bin/clipse -listen-shell";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      # solaar = {
      #   Unit = {
      #     Description = "Solaar tray daemon";
      #     After = ["graphical-session.target"];
      #     PartOf = ["graphical-session.target"];
      #   };
      #   Service = {
      #     ExecStart = "${pkgs.solaar}/bin/solaar -w hide";
      #     Restart = "on-failure";
      #     RestartSec = 5;
      #   };
      #   Install.WantedBy = ["graphical-session.target"];
      # };
    };
  };
}
