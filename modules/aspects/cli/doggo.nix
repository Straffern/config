{den, ...}: {
  den.aspects.cli.doggo.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.doggo];
  };
}
