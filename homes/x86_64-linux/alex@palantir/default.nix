{
  pkgs,
  namespace,
  ...
}: let
  inherit (pkgs.${namespace}) clipy;
in {
  programs.zsh.sessionVariables = {
    PATH = "$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
  };

  asgaard = {
    cli.shells.zsh.enable = true;
    cli.programs.ai = {
      enable = true;
      opencode = {
        enable = true;
      };
    };
    cli.programs.git.signingKey = null;
    suites.development.enable = true;
    styles.stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    };
  };

  home.packages = [clipy];
  home.stateVersion = "26.05";
}
