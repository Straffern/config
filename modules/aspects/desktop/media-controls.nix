{den, ...}: {
  den.aspects.desktop.media-controls.homeManager = {pkgs, ...}: {
    services.playerctld.enable = true;
    home.packages = with pkgs; [
      ffmpeg
      mpv
      pamixer
      playerctl
    ];
  };
}
