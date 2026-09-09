{den, ...}: {
  den.aspects.styles.icons.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    package = pkgs.catppuccin-papirus-folders.override {
      flavor = "mocha";
      accent = "lavender";
    };
  in {
    home.packages = [package];
    gtk = lib.mkIf (!(config.programs.dank-material-shell.enable or false)) {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        inherit package;
      };
    };
  };
}
