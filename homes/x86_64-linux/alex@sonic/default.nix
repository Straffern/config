{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }:
let
  waldl = pkgs.${namespace}.waldl.override {
    walldir = "~/.dotfiles/packages/wallpapers/wallpapers";
    sorting = "toplist";
    quality = "original";
    atleast = "2560x1440";
  };

  clipy = pkgs.${namespace}.clipy;

  # sshHosts = {
  #   "frostmourne" = {
  #     hostname = "%(cat ${config.sops.secrets.frostmourne_ip.path})";
  #     user = "alex";
  #   };
  # };

in {

  programs.zsh.sessionVariables = {
    PATH =
      "$XDG_BIN_HOME:$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
  };

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

    cli.programs.ai = {
      enable = true;
      claude.enable = true;
      opencode = {
        enable = true;
        convertAgents = true;
        convertCommands = true;
      };
      includeModelInAgents = false;
      shellFunction = {
        enable = true;
        # model = null;  # Uses OpenCode's default model
        # systemPrompt = "...";  # Custom system prompt
      };
      # Optional: Configure specific agent providers or temperature overrides
      # agentProviders = {
      #   "elixir-expert" = "cerebras/qwen3-coder";
      # };
      # temperatureOverrides = {
      #   "creative-agent" = 0.7;
      # };
    };
    suites = {
      desktop.enable = true;
      social.enable = true;
    };
    styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.cat_in_window;
    # styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.osaka-jade-bg;

  };
  wayland.windowManager.hyprland.settings.monitor =
    lib.mkForce "eDP-1, preferred, auto, 1.5";
  sops.secrets.ssh_config = { sopsFile = ../../../secrets.yaml; };

  programs.ssh.includes = [ config.sops.secrets.ssh_config.path ];

  home.packages = with pkgs; [ nwg-displays waldl clipy uv ];
  home.stateVersion = "23.11";
}
