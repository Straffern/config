{den, ...}: {
  den.aspects.cli.ripgrep.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.ripgrep];
  };
}
