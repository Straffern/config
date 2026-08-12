{den, ...}: {
  den.aspects.cli.nodejs.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.nodejs_24];
  };
}
