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
    PATH = "$XDG_BIN_HOME:$HOME/go/bin:$HOME/.npm-global/bin:$PATH:$XDG_CACHE_HOME/.bun/bin";
  };

  asgaard = {
    desktops = {
      niri.enable = true;
      shells.dms.enable = true;
    };

    cli = {
      terminals.alacritty.enable = true;
      programs = {
        lobster.enable = true;
        omp.enable = true;
        ai = {
          enable = true;
          opencode = {enable = true;};
          shellFunction = {
            enable = true;
            model = "openai-codex/gpt-5.1-codex-mini";
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
  };
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
