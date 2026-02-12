{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (pkgs.${namespace}) clipy;
in {
  programs.zsh.sessionVariables = {
    PATH = "$XDG_BIN_HOME:$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
  };

  asgaard = {
    desktops.hyprland.enable = true;

    cli = {
      terminals.alacritty.enable = true;
      programs = {
        lobster.enable = true;
        ai = {
          enable = true;
          opencode = {enable = true;};
          shellFunction = {
            enable = true;
            model = "opencode/gpt-5-nano";
            # systemPrompt = "...";  # Custom system prompt
          };
        };
      };
    };
    programs.waldl = {
      enable = true;
      walldir = "/home/alex/.dotfiles/packages/wallpapers/wallpapers";
    };
    suites = {
      desktop.enable = true;
      social.enable = true;
    };
    styles.stylix = {
      wallpaper = pkgs.${namespace}.wallpapers.cat_in_window;
      # patch = {
      #   # contrast = 20;
      #   recolor = false;
      # };
    };
    # styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.osaka-jade-bg;
  };
  wayland.windowManager.hyprland.settings.monitor =
    lib.mkForce "eDP-1, preferred, auto, 1.5";
  sops.secrets.ssh_config = {sopsFile = ../../../secrets.yaml;};

  programs.ssh.includes = [config.sops.secrets.ssh_config.path];

  home.packages = with pkgs; [
    nwg-displays
    clipy
    uv
    v4l-utils
    guvcview
  ];
  home.stateVersion = "23.11";
}
