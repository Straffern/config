{den, ...}: {
  den.aspects.cli.gping.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.gping];
  };
}
