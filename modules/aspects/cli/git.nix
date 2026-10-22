{den, ...}: {
  den.aspects.cli.git = {
    includes = [den.aspects.cli.lumen];
    homeManager = {
      config,
      inputs',
      lib,
      host,
      pkgs,
      ...
    }:
      lib.mkMerge [
        {
          home.packages = with pkgs; [
            lazygit
            delta
          ];
          home.file.".config/lazygit/config.yml".text = ''
            git:
              overrideGpg: true
          '';
          programs.git = {
            enable = true;
            package = inputs'.unstable.legacyPackages.git;
            # The GitHub key signs from the agent, so agents sign too: a signature says a commit came
            # from my machines, not that I typed it.
            signing.signByDefault = true;
            ignores = [
              ".aider*"
              ".beads/"
              ".devenv/"
              ".direnv/"
            ];
            settings = {
              user = {
                name = "Alexander Flensborg";
                email = "alex@flensborg.dev";
                signingkey = "~/.ssh/github.pub";
              };
              alias = {
                lg1 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
                lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
                lg = "lg1";
              };
              gpg.format = "ssh";
              core = {
                editor = "nvim";
                pager = "delta";
              };
              color.ui = true;
              interactive.diffFitler = "delta --color-only";
              delta = {
                enable = true;
                navigate = true;
                light = false;
                side-by-side = false;
                options.syntax-theme = "catppuccin";
              };
              rerere.enabled = true;
              rebase.autoStash = true;
              pull = {
                ff = "only";
                rebase = true;
              };
              push = {
                default = "current";
                autoSetupRemote = true;
              };
              init.defaultBranch = "master";
              safe.directory = [
                "/home/${config.home.username}/.dotfiles"
                "/home/${config.home.username}/.cache/nix/tarball-cache"
              ];
              "url.git@github.com:".insteadOf = [
                "https://github.com/"
                "http://github.com/"
              ];
              "url.git@gitlab.com:".insteadOf = [
                "https://gitlab.com/"
                "http://gitlab.com/"
              ];
            };
          };
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          home.persistence."/persist".directories = [".config/lazygit"];
        })
      ];
  };
}
