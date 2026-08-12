{den, ...}: {
  den.aspects.profiles.desktop = {
    includes = [
      den.aspects.profiles.common
      den.aspects.profiles.development
      den.aspects.apps.kdeconnect
      den.aspects.apps.spotify
      den.aspects.apps.trayscale
      den.aspects.apps.foliate
      den.aspects.apps.pavucontrol
      den.aspects.apps.pwvucontrol
      den.aspects.apps.sushi
      den.aspects.apps.gnome-disk-utility
      den.aspects.apps.totem
      den.aspects.apps.loupe
      den.aspects.apps.nautilus
      den.aspects.desktop.base
      den.aspects.desktop.nautilus
      den.aspects.hardware.audio
      den.aspects.network.avahi
      den.aspects.network.vpn
      den.aspects.virtualization.podman
      den.aspects.services.ydotool
      den.aspects.platform.nh
      den.aspects.platform.nix-ld
      den.aspects.platform.boot-plymouth
    ];
    homeManager = {pkgs, ...}: {
      services.playerctld.enable = true;
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
        satty
      ];
    };
  };
}
