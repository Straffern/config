{den, ...}: {
  den.aspects.cli.go.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.go];
  };
}
