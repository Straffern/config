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

    home.packages = with pkgs; [ nwg-displays ];

    suites = {
      desktop.enable = true;
      social.enable = true;
    };

    user = {
      enable = true;
      name = "alex";
    };

    home.stateVersion = "24.11";
  };
}
