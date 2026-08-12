{den, ...}: {
  den.aspects.cli.entr.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.entr];
  };
}
