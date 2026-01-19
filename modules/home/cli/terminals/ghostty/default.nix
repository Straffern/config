{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace}; let
  cfg = config.${namespace}.cli.terminals.ghostty;
in {
  options.${namespace}.cli.terminals.ghostty = {
    enable = mkBoolOpt false "enable ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    catppuccin.ghostty.enable =
      config.${namespace}.styles.stylix.useCatppuccinNative;

    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        font-family = "${config.stylix.fonts.monospace.name}";
        font-size = config.stylix.fonts.sizes.terminal;

        # Performance
        window-vsync = false;
        async-backend = "io_uring";
        confirm-close-surface = false;
        copy-on-select = "clipboard";

        # Window
        window-padding-x = 10;
        window-padding-y = 10;
        window-decoration = false;
        background-opacity = config.stylix.opacity.terminal;
        gtk-titlebar = false;

        # Cursor
        cursor-style = "block";
        cursor-style-blink = false;

        # Integration
        # Use zsh to match other terminals in this repo
        command = "zsh";

        # Mouse
        mouse-hide-while-typing = true;

        # Working directory - always start in home, never inherit
        window-inherit-working-directory = false;
        working-directory = "home";
      };
    };
  };
}
