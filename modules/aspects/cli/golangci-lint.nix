{den, ...}: {
  den.aspects.cli.golangci-lint.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.golangci-lint];
  };
}
