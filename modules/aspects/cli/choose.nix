{den, ...}: {
  den.aspects.cli.choose.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.choose];
  };
}
