{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace}; let
  cfg = config.${namespace}.cli.terminals.alacritty;
  dmsEnabled = config.programs.dank-material-shell.enable;
in {
  options.${namespace}.cli.terminals.alacritty = with types; {
    enable = mkBoolOpt false "enable alacritty terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        general = mkIf dmsEnabled {
          import = ["~/.config/alacritty/dank-theme.toml"];
        };

        shell = {program = "zsh";};

        window = {
          padding = {
            x = 30;
            y = 30;
          };
          decorations = "none";
        };

        selection = {save_to_clipboard = true;};

        mouse_bindings = [
          {
            mouse = "Right";
            action = "Paste";
          }
        ];

        env = {TERM = "xterm-256color";};
      };
    };
  };
}
