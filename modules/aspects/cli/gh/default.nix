{den, ...}: let
  ghForkCleanup = pkgs: pkgs.callPackage ./_package/gh-fork-cleanup.nix {};
in {
  den.aspects.cli.gh = {
    homeManager = {
      config,
      pkgs,
      ...
    }: {
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
        };
        gitCredentialHelper.enable = true;
        extensions = with pkgs; [
          gh-dash
          gh-eco
          gh-stack
          (ghForkCleanup pkgs)
        ];
      };
      home.persistence."/persist".directories = [".config/gh"];
    };
    packages = {pkgs, ...}: {
      gh-fork-cleanup = ghForkCleanup pkgs;
    };
  };
}
