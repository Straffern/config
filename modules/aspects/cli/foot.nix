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
    };
  };
}
