{den, ...}: {
  den.aspects.cli.hexyl.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.hexyl];
  };
}
