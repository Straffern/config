{den, ...}: {
  den.aspects.cli.tailspin.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.tailspin];
  };
}
