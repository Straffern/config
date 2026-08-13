{den, ...}: {
  den.aspects.cli.toolbox.homeManager = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      (lib.hiPrio parallel)
      broot
      chafa
      choose
      curlie
      doggo
      duf
      dust
      dysk
      entr
      erdtree
      fd
      ffmpeg
      gdu
      git-remote-gcrypt
      gping
      grex
      gtrash
      hexyl
      hyperfine
      jnv
      jq
      jqp
      libinput
      moreutils
      ouch
      procs
      python3
      ripgrep
      sd
      silver-searcher
      sshfs
      tailspin
      tealdeer
      tokei
      trash-cli
      unzip
      viddy
      wl-clipboard
      xcp
      yq
    ];
  };
}
