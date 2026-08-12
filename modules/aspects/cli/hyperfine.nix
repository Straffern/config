{den, ...}: {
  den.aspects.cli.hyperfine.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.hyperfine];
  };
}
