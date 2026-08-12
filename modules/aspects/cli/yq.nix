{den, ...}: {
  den.aspects.cli.yq.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.yq-go];
  };
}
