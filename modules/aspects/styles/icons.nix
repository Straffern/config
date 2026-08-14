{den, ...}: {
  den.aspects.styles.icons.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      tela-icon-theme
      tela-circle-icon-theme
    ];
    gtk.iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "lavender";
      };
    };
  };
}
