{den, ...}: {
  den.aspects.cli.git-remote-gcrypt.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.git-remote-gcrypt];
  };
}
