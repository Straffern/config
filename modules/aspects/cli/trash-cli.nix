{den, ...}: {
  den.aspects.cli.trash-cli.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.trash-cli];
  };
}
