{den, ...}: {
  den.aspects.cli.sshfs.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.sshfs];
  };
}
