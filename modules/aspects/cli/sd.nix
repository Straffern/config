{den, ...}: {
  den.aspects.cli.sd.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.sd];
  };
}
