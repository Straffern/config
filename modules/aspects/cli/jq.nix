{den, ...}: {
  den.aspects.cli.jq.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.jq];
  };
}
