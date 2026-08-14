{
  den,
  inputs,
  ...
}: {
  den.aspects.cli.zsh = {
    nixos = {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        enableGlobalCompInit = false;
        interactiveShellInit = ''
          if [[ $EUID -eq 0 && -z ''${__HM_ZSH_SESS_VARS_SOURCED+x} ]]; then
            autoload -U compinit && compinit
          fi
        '';
      };
      environment.pathsToLink = ["/share/zsh"];
    };

    homeManager = {
      config,
      lib,
      host,
      pkgs,
      ...
    }:
      lib.mkMerge [
        {
          programs.zsh = {
            enable = true;
            enableCompletion = true;
            completionInit = ''
              # Add custom completions directory to fpath
              fpath=(${config.xdg.configHome}/zsh/completions $fpath)

              # HM owns compinit (NixOS enableGlobalCompInit = false).
              # Use -C to skip fpath rescan when dump is fresh (< 1 day old).
              autoload -Uz compinit
              if [[ -f ''${ZDOTDIR:-$HOME}/.zcompdump && $(find ''${ZDOTDIR:-$HOME}/.zcompdump -mtime -1 2>/dev/null) ]]; then
                compinit -C
              else
                compinit
              fi
            '';
            autosuggestion = {
              enable = true;
            };
            syntaxHighlighting = {
              enable = true;
            };
            history = {
              size = 5000;
              save = 5000;
              path = "${config.xdg.dataHome}/zsh/history";
              share = true;
              ignorePatterns = [
                "ls"
                "ll"
                "cat"
              ];
              ignoreAllDups = true;
            };
            historySubstringSearch.enable = true;
            shellAliases = {
              ls = "eza --icons --git";
              ll = "eza -la --icons --git";
              cat = "bat";
            };
            dotDir = "${config.xdg.configHome}/zsh";
            initContent = ''
              setopt APPEND_HISTORY
              setopt HIST_SAVE_NO_DUPS
              setopt HIST_FIND_NO_DUPS

              export SUDO_PROMPT=$'\a[sudo] password for %p: '
              # SUDO_PROMPT is text-only, it cannot execute commands.
              # If wanted, use this wrapper to notify right before sudo prompts:
              # sudo() {
              #   if ! command sudo -n true 2>/dev/null; then
              #     command -v notify-send >/dev/null && notify-send "sudo" "Password prompt incoming"
              #   fi
              #   command sudo "$@"
              # }

              # zsh-vi-mode configuration
              function zvm_config() {
                ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
                ZVM_SYSTEM_CLIPBOARD_ENABLED=true
                ZVM_VI_SURROUND_BINDKEY=s-prefix
              }

              function zvm_after_init() {
                # history-substring-search bindings
                zvm_bindkey viins '^[[A' history-substring-search-up
                zvm_bindkey viins '^[[B' history-substring-search-down
                zvm_bindkey vicmd 'k' history-substring-search-up
                zvm_bindkey vicmd 'j' history-substring-search-down

                # fzf history search
                zvm_bindkey viins '^R' fzf-history-widget
              }
            '';
            plugins = [
              {
                name = "zsh-vi-mode";
                src = pkgs.zsh-vi-mode;
                file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
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
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          home.persistence."/persist".directories = [".local/share/zsh"];
        })
      ];
  };
}
