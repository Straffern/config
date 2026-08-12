{den, ...}: {
  den.aspects.cli.procs.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.procs];
  };
}
