{den, ...}: {
  den.aspects.desktop.addons.qt = {
    homeManager = {
      lib,
      pkgs,
      ...
    }: {
      qt = {
        enable = true;
        platformTheme = "gtk2";
        style = {
          name = "adwaita-dark";
          package = pkgs.adwaita-qt;
        };
      };
    };
  };
}
