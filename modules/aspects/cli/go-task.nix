{den, ...}: {
  den.aspects.cli.go-task.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.go-task];
  };
}
