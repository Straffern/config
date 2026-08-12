{den, ...}: {
  den.aspects.cli.gotools.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.gotools];
  };
}
