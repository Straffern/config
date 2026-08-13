{den, ...}: {
  den.aspects.cli.sourcegraph.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.src-cli];
  };
}
