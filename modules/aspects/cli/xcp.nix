{den, ...}: {
  den.aspects.cli.xcp.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.xcp];
  };
}
