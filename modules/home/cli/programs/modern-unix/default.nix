{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.modern-unix;
in {
  options.${namespace}.cli.programs.modern-unix = {
    enable = mkEnableOption "Modern unix tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      broot
      choose
      curlie
      chafa
      doggo
      duf
      delta
      dust
      dysk
      entr
      erdtree
      fd
      gdu
      gping
      grex
      hyperfine
      hexyl
      jqp
      jnv
      ouch
      silver-searcher
      procs
      tokei
      trash-cli
      tailspin
      gtrash
      ripgrep
      sd
      xcp
      yq-go
      viddy
      snitch

      kaf

      lazysql
      asgaard.lazyjournal

      jq
      tealdeer

      # go
      go
      golangci-lint
      air
      templ
      sqlc
      golines
      gotools
      go-task
      go-mockery
      gotestsum

      nodejs_24
      bun
    ];
  };
}
