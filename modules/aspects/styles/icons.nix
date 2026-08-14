{den, ...}: {
  den.aspects.styles.icons.homeManager = {pkgs, ...}: {
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "lavender";
        };
      };
    };
  };
}
