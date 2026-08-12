{den, ...}: {
  den.aspects.cli.jqp.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.jqp];
  };
}
