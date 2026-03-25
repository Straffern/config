{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.${namespace}.styles.fonts;
in {
  options.${namespace}.styles.fonts = {
    enable = mkEnableOption "Curated font and icon theme collection";
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      # Nerd Fonts (patched with glyphs for statuslines, prompts, etc.)
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.monaspace
      nerd-fonts.commit-mono
      nerd-fonts.victor-mono
      nerd-fonts.geist-mono
      nerd-fonts.caskaydia-cove # Cascadia Code patched

      # Monospace (unpatched)
      cascadia-code
      commit-mono
      intel-one-mono
      ibm-plex
      maple-mono.NF

      # Proportional — sans
      inter
      geist-font
      lexend
      source-sans
      open-sans

      # Proportional — serif
      source-serif

      # Emoji
      noto-fonts-color-emoji

      # Icon themes
      tela-icon-theme
      tela-circle-icon-theme
      (catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "lavender";
      })
    ];
  };
}
