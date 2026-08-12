{den, ...}: {
  den.aspects.cli.gotestsum.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.gotestsum];
  };
}
