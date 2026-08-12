{den, ...}: {
  den.aspects.cli.chafa.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.chafa];
  };
}
