{den, ...}: {
  den.aspects.cli.libinput.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.libinput];
  };
}
