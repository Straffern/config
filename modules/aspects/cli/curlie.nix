{den, ...}: {
  den.aspects.cli.curlie.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.curlie];
  };
}
