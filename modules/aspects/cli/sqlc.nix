{den, ...}: {
  den.aspects.cli.sqlc.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.sqlc];
  };
}
