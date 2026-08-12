{den, ...}: {
  den.aspects.cli.air.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.air];
  };
}
