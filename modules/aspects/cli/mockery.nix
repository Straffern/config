{den, ...}: {
  den.aspects.cli.mockery.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.go-mockery];
  };
}
