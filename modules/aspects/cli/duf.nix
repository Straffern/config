{den, ...}: {
  den.aspects.cli.duf.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.duf];
  };
}
