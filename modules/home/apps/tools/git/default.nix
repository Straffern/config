{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkOpt types mkIf;
  cfg = config.${namespace}.tools.git;
in {
  options.${namespace}.tools.git = {
    enable = mkEnableOption "Git";
    name = mkOpt {
      type = types.str;
      description = "Name of the Git user, this will appear on each commit.";
    };
    email = mkOpt {
      type = types.str;
      description = "Email of the Git user, this will appear on each commit.";
    };

    # This might need to be modified to config.snowfallorg.user.name
    sshKeyPath = mkOpt {
      type = types.str;
      default = "/home/${config.home.username}/.ssh/id_ed25519.pub";
      description = "Direct path to ssh public key";
    };

    safe-dirs = mkOpt {
      type = types.listOf types.str;
      default = [ "/home/${config.home.username}/.dotfiles" ];
      description =
        "Add any path here, that might belong to root, but is part of Git.";
    };
  };

  config = mkIf cfg.enable {

    programs.git = {
      enable = true;
      aliases = {
        lg1 =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
        lg2 =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n'          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
        lg = "lg1";
      };
      userName = cfg.name;
      userEmail = cfg.email;

      # TODO: add signing config

      extraConfig = {
        pull = {
          ff = "only";
          rebase = true;
        };

        rerere.enabled = true;

        rebase.autoStash = true;

        safe.directory = cfg.safe-dirs
          ++ [ "/home/${config.home.username}/.cache/nix/tarball-cache" ];
      };
    };
  };
}
