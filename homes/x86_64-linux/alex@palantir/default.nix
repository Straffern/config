{ lib, pkgs, config, osConfig ? { }, format ? "unknown", namespace, ... }:
let

  clipy = pkgs.${namespace}.clipy;

in {

  programs.zsh.sessionVariables = {
    PATH =
      "$HOME/go/bin:$HOME/.local/cache/.bun/bin:$HOME/.npm-global/bin:$PATH";
  };

  asgaard = {

  };

  home.packages = with pkgs; [ clipy uv ];
  home.stateVersion = "23.11";
}
