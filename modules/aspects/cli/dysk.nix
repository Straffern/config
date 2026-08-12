{den, ...}: {
  den.aspects.cli.dysk.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.dysk];
  };
}
