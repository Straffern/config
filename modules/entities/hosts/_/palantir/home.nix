_: {
  den.aspects._palantir-home.homeManager = {
    lib,
    pkgs,
    ...
  }: {
    programs.zsh.sessionVariables.PATH = "$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
    programs.git = {
      signing = {
        key = null;
        signByDefault = lib.mkForce false;
      };
      settings.commit.gpgsign = lib.mkForce false;
    };
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    };
  };
}
