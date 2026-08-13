{den, ...}: {
  den.aspects.cli.shell-utils.homeManager = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      (lib.hiPrio parallel)
      moreutils
    ];
  };
}
