{ lib, pkgs, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.cli.shells.zsh;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;

  # XDG-compliant history location
  historyDir = "${config.xdg.dataHome}/zsh";
  historyFile = "${historyDir}/history";
in {
  options.${namespace}.cli.shells.zsh = {
    enable = mkEnableOption "Zsh";

    initContent = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    # users.defaultShell = pkgs.zsh;
    # users.users.root.shell = pkgs.bashInteractive;

    programs.zsh = {
      enable = true;
      defaultKeymap = "viins";
      enableCompletion = true;
      autosuggestion = enabled;
      syntaxHighlighting = enabled;

      history = {
        size = 5000;
        save = 5000;
        path = historyFile;
        share = true;
        ignorePatterns = [ "ls" "ll" "cat" ];
        ignoreAllDups = true;

      };
      historySubstringSearch = {
        enable = true;
        searchUpKey = "^R";
        searchDownKey = "^F";
      };

      shellAliases = {
        ls = "eza --icons --git";
        ll = "eza -la --icons --git";
        cat = "bat";
      };

      dotDir = "${config.xdg.configHome}/zsh";
      # initExtraFirst =
      #   "source /home/${config.home.username}/${dotDir}/.p10k.zsh";
      initContent = lib.mkMerge [
        ''
          setopt APPEND_HISTORY
          setopt HIST_SAVE_NO_DUPS
          setopt HIST_FIND_NO_DUPS
        ''
        cfg.initContent
      ];
      plugins = [
        # {
        #   name = "powerlevel10k";
        #   src = pkgs.zsh-powerlevel10k;
        #   file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        # }
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

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".local/share/zsh" ];
    };
  };
}
