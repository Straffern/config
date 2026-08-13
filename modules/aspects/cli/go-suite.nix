{den, ...}: {
  den.aspects.cli.go-suite.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      air
      go
      go-mockery
      go-task
      golangci-lint
      golines
      gotestsum
      gotools
      sqlc
      templ
    ];
  };
}
