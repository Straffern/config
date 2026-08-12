{den, ...}: {
  den.aspects.cli.gtrash.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.gtrash];
  };
}
