{den, ...}: {
  den.aspects.cli.database.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.termdbms pkgs.lazysql];
  };
}
