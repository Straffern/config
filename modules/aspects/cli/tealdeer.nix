{den, ...}: {
  den.aspects.cli.tealdeer.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.tealdeer];
  };
}
