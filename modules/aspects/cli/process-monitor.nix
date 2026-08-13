{den, ...}: {
  den.aspects.cli.process-monitor.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.btop];
  };
}
