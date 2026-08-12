{den, ...}: {
  den.aspects.apps.shotwell.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.shotwell];
  };
}
