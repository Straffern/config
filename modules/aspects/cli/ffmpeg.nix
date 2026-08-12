{den, ...}: {
  den.aspects.cli.ffmpeg.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.ffmpeg];
  };
}
