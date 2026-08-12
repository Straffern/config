{den, ...}: {
  den.aspects.cli.unzip.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.unzip];
  };
}
