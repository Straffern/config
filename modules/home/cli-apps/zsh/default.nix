{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.cli-apps.zsh;
in {
  options.${namespace}.cli-apps.zsh = { enable = mkEnableOption "Zsh"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ eza bat nitch ];

    users.defaultShell = pkgs.zsh;
    users.users.root.shell = pkgs.bashInteractive;

    program.zsh = rec {
      enable = true;
      defaultKeyMap = "viins";
      enableCompletion = true;
      autosuggestion = enabled;
      syntaxHighlighting = enabled;

      history = {
        size = 5000;
        save = 5000;
        path = "/home/${config.home.username}/.zsh_history";
        share = true;
        ignorePatterns = [ "ls" "ll" "cat" ];
        ignoreAllDups = true;

      };
      historySubstringSearch = {
        enable = true;
        searchUpKey = "^R";
        searchDownKey = "^F";
      };

      shellAliases = config.environment.shellAliases // {
        ls = "eza --icons --git";
        ll = "eza -la --icons --git";
        cat = "bat";
      };

      dotDir = ".config/zsh";
      initExtraFirst =
        "source /home/${config.home.username}/${dotDir}/.p10k.zsh";
      initExtra = lib.concatStringsSep "\n" ([
        "setopt APPEND_HISTORY"
        "setopt HIST_SAVE_NO_DUPS"
        "setopt HIST_FIND_NO_DUPS"
        cfg.initExtra
      ]);
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "zsh-completions";
          file = "zsh-completions.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-completions";
            rev = "0.35.0";
            sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg=";
          };
        }
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
          };
        }
      ];

    };

    # home.programs.zoxide = enabled;
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
