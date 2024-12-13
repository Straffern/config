{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }:
with lib.${namespace}; {
  asgaard = {
    cli-apps = {
      zsh = enabled;
      neovim = enabled;
      home-manager = enabled;
    };

    system = {
      gtk = enabled;
      xdg-portal = enabled;
      hypridle = enabled;
      hyprland = enabled;
      hyprlock = enabled;
      hyprpanel = enabled;
      hyprpaper = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
      devenv = enabled;
    };
  };
}
