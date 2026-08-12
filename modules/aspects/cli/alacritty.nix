{
  den,
  inputs,
  ...
}: {
  den.aspects.cli.alacritty = {
    homeManager = {
      config,
      lib,
      ...
    }: {
      programs.alacritty = {
        enable = true;
        settings = {
          general = lib.mkIf config.programs.dank-material-shell.enable {
            import = ["~/.config/alacritty/dank-theme.toml"];
          };
          shell.program = "zsh";
          window = {
            padding = {
              x = 30;
              y = 30;
            };
            decorations = "none";
          };
          selection.save_to_clipboard = true;
          mouse_bindings = [
            {
              mouse = "Right";
              action = "Paste";
            }
          ];
          env.TERM = "xterm-256color";
        };
      };
    };
  };
}
