{den, ...}: {
  den.aspects.styles.fonts = {
    includes = [den.aspects.styles.packages];

    homeManager = {pkgs, ...}: {
      fonts.fontconfig.enable = true;
      home.packages = with pkgs; [
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.iosevka
        nerd-fonts.monaspace
        nerd-fonts.commit-mono
        nerd-fonts.victor-mono
        nerd-fonts.geist-mono
        nerd-fonts.caskaydia-cove
        cascadia-code
        commit-mono
        intel-one-mono
        ibm-plex
        maple-mono.NF
        inter
        geist-font
        lexend
        source-sans
        open-sans
        source-serif
        noto-fonts-color-emoji
        tela-icon-theme
        tela-circle-icon-theme
        (catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "lavender";
        })
      ];
    };

    nixos = _: {
      fonts = {
        enableDefaultPackages = true;
        fontDir.enable = true;
        fontconfig = {
          enable = true;
          localConf = ''
            <alias>
              <family>monospace</family>
              <prefer><family>Symbols Nerd Font</family></prefer>
            </alias>
          '';
        };
      };
    };
  };
}
