{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption types mkOption;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.cli.programs.git;

  rewriteURL = lib.mapAttrs' (key: value: {
    name = "url.${key}";
    value = { insteadOf = value; };
  }) cfg.urlRewrites;
in {
  options.${namespace}.cli.programs.git = with types; {
    enable = mkEnableOption "Git";
    userName = mkOpt (nullOr str) "Alexander Flensborg"
      "The name appearing on the commits";
    email =
      mkOpt (nullOr str) "alex@flensborg.dev" "The email to use with git.";
    urlRewrites =
      mkOpt (attrsOf str) { } "url we need to rewrite i.e. ssh to http";
    allowedSigners = mkOpt str "" "The public key used for signing commits";

    safeDirs = mkOption {
      type = types.listOf types.str;
      default = [ "/home/${config.home.username}/.dotfiles" ];
      description =
        "Add any path here, that might belong to root, but is part of Git.";
    };
  };

  config = mkIf cfg.enable {
    home.file.".ssh/allowed_signers".text = "* ${cfg.allowedSigners}";

    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.email;

      aliases = {
        lg1 =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
        lg2 =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
        lg = "lg1";
      };

      extraConfig = {
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        commit.gpgsign = true;
        user.signingkey = "~/.ssh/id_ed25519.pub";

        core = {
          editor = "nvim";
          pager = "delta";
        };

        color = { ui = true; };

        interactive = { diffFitler = "delta --color-only"; };

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

        init = { defaultBranch = "master"; };

        safe.directory = cfg.safeDirs
          ++ [ "/home/${config.home.username}/.cache/nix/tarball-cache" ];
      } // rewriteURL;
    };
  };
}
