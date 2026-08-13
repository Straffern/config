{den, ...}: {
  den.aspects.desktop.base.homeManager = {pkgs, ...}: {
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = ["graphical-session-pre.target"];
      };
    };
    home.packages = with pkgs; [
      jmtpfs
      brightnessctl
      xdg-utils
    ];
  };
}
