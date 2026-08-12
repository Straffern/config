{den, ...}: {
  den.aspects.cli.dust.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.dust];
  };
}
