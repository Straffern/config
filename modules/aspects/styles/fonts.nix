{den, ...}: {
  den.aspects.styles.fonts = {
    includes = [den.aspects.styles.monolisa];
    homeManager = {pkgs, ...}: {
      fonts.fontconfig.enable = true;
      home.packages = [pkgs.nerd-fonts.symbols-only];
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
