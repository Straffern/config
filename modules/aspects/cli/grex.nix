{den, ...}: {
  den.aspects.cli.grex.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.grex];
  };
}
