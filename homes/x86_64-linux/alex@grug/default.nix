{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }:
let
  waldl = pkgs.${namespace}.waldl.override {
    walldir = "~/.dotfiles/packages/wallpapers/wallpapers";
    sorting = "toplist";
    quality = "original";
    atleast = "2560x1440";
  };

in {
  asgaard = {
    desktops = {
      hyprland = {
        enable = true;
        execOnceExtras = [
          "${pkgs.trayscale}/bin/trayscale"
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "${pkgs.blueman}/bin/blueman-applet"
        ];
      };
    };

    cli.terminals.alacritty.enable = true;
    suites = {
      desktop.enable = true;
      social.enable = true;
    };
    styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.cat_in_window;

    user = {
      enable = true;
      name = "alex";
    };

  };

  home.packages = with pkgs; [ nwg-displays waldl ];

  home.stateVersion = "23.11";
}
