{den, ...}: {
  den.aspects.cli.tokei.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.tokei];
  };
}
