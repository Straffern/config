{
  den.aspects.cli.foot.homeManager = {
    config,
    lib,
    ...
  }: {
    programs.foot = {
      enable = true;
      # Server starts with graphical-session.target, so the first footclient after login opens instantly.
      server.enable = true;
      settings.main = {
        shell = "zsh";
        pad = "10x10";
        include = lib.mkIf (config.programs.dank-material-shell.enable or false) "${config.xdg.configHome}/foot/dank-colors.ini";
      };
      # Foot defaults swallow omp's Ctrl+Shift+o (tool visibility) and Ctrl+Shift+x (overlay).
      # Prompt jumps need OSC 133 marks, which tmux doesn't forward anyway.
      settings.key-bindings = {
        show-urls-launch = "Control+Shift+l";
        prompt-prev = "none";
        prompt-next = "none";
      };
    };
  };
}
