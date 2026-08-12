{den, ...}: {
  den.aspects.cli.gdu.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.gdu];
  };
}
