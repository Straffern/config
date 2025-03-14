{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }:
let
  waldl = pkgs.${namespace}.waldl.override {
    walldir = "~/.dotfiles/packages/wallpapers/wallpapers";
    sorting = "toplist";
    quality = "original";
    atleast = "2560x1440";
  };

  sshHosts = {
    "frostmourne" = {
      host = config.sops.secrets.frostmourne_ip.path;
      user = "alex";
    };
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
    cli.programs.lobster.enable = true;
    cli.programs.ssh.extraHosts = sshHosts;
    suites = {
      desktop.enable = true;
      social.enable = true;
    };
    styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.cat_in_window;

  };
  sops.secrets.frostmourne_ip = { sopsFile = ../../../secrets.yaml; };

  home.packages = with pkgs; [ nwg-displays waldl aider-chat goose-cli ];
  home.stateVersion = "23.11";
}
