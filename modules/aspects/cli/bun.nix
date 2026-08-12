{den, ...}: {
  den.aspects.cli.bun.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.bun];
  };
}
