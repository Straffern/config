{den, ...}: {
  den.aspects.cli.broot.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.broot];
  };
}
