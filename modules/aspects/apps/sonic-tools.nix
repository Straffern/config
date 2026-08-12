{den, ...}: {
  den.aspects.apps.nwg-displays.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.nwg-displays];
  };
  den.aspects.apps.guvcview.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.guvcview];
  };
}
