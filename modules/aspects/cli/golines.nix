{den, ...}: {
  den.aspects.cli.golines.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.golines];
  };
}
