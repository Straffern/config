{den, ...}: {
  den.aspects.cli.erdtree.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.erdtree];
  };
}
