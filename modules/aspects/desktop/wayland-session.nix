{den, ...}: {
  den.aspects.desktop.wayland-session.homeManager = {pkgs, ...}: {
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      LIBSEAT_BACKEND = "logind";
    };
    home.packages = with pkgs; [
      clipse
      slurp
      sway-contrib.grimshot
      satty
      wl-clipboard
    ];
  };
}
