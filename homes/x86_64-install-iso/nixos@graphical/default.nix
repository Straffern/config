{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }: {

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

    suites = { desktop.enable = true; };

    styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.ign_cityRainOther;
  };
}
