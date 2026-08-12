{den, ...}: {
  den.aspects.cli.python.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.python3];
  };
}
