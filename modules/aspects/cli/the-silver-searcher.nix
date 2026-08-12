{den, ...}: {
  den.aspects.cli.the-silver-searcher.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.silver-searcher];
  };
}
