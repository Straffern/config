{den, ...}: {
  den.aspects.cli.viddy.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.viddy];
  };
}
