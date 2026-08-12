{den, ...}: {
  den.aspects.cli.wl-clipboard.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.wl-clipboard];
  };
}
