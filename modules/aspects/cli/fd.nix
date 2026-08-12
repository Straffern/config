{den, ...}: {
  den.aspects.cli.fd.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.fd];
  };
}
