{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }:
let

  clipy = pkgs.${namespace}.clipy;

in {

  programs.zsh.sessionVariables = {
    PATH = "$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
  };

  asgaard = {
    cli.shells.zsh.enable = true;
    cli.programs.ai = {
      enable = true;
      claude.enable = true;
      opencode = {
        enable = true;
        convertAgents = true;
        convertCommands = true;
      };
      includeModelInAgents = false;
    };
    suites.development.enable = true;
    styles.stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    };
  };

  home.packages = with pkgs; [ clipy ];
  home.stateVersion = "23.11";
}
