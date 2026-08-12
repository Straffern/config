{den, ...}: {
  den.aspects.cli.ouch.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.ouch];
  };
}
