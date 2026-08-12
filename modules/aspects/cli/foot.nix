{
  den,
  inputs,
  ...
}: {
  den.aspects.cli.foot = {
    homeManager = {
      config,
      lib,
      ...
    }: {
      programs.foot = {
        enable = true;
        settings = {
          main =
            {
              shell = "zsh";
              pad = "15x15";
              selection-target = "clipboard";
            }
            // lib.optionalAttrs config.programs.dank-material-shell.enable {
              include = "${config.xdg.configHome}/foot/dank-colors.ini";
            };
          scrollback.lines = 10000;
        };
      };
    };
  };
}
