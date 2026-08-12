{den, ...}: {
  den.aspects.cli.jnv.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.jnv];
  };
}
