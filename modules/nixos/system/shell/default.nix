{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.system.shell;
in {
  options.system.shell = with types; {
    shell = mkOpt (enum ["zsh" "nushell" "fish"]) "nushell" "What shell to use";
    initExtra = mkOpt str "" "ExtraShellInit";
  };

  config = {
    environment.systemPackages = with pkgs; [
      eza
      bat
      nitch
    ] ++ optionals (cfg.shell == "fish" || cfg.shell == "nushell") [
      zoxide 
      starship
    ] ++ optionals (cfg.shell == "zsh") [
      meslo-lgs-nf
    ];

    users.defaultUserShell = pkgs.${cfg.shell};
    users.users.root.shell = pkgs.bashInteractive;

    home.programs.starship = mkIf (cfg.shell == "fish" || cfg.shell == "nushell") {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };

    home.configFile."starship.toml".source = ./starship.toml;

    environment.shellAliases = {
      ".." = "cd ..";
      neofetch = "nitch";
    };

    home.programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
     
    home.programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
    home.persist.directories = [
      ".local/share/zoxide"
      ".cache/zoxide"
      ".cache/starship"
      ".config/nushell"
      ".config/fish"
      ".config/zsh"
    ];


    environment.pathsToLink = [ "/share/zsh" ];
    home.programs.zsh = mkIf (cfg.shell == "zsh") rec {
      enable = true;
      enableCompletion = true;
      autosuggestion = enabled;
      syntaxHighlighting = enabled;

      history = {
        size = 5000;
        save = 5000;
        path = "~/.zsh_history";
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

      dotDir = ".config/zsh";
      initExtraFirst = "source /home/${config.user.name}/${dotDir}/.p10k.zsh";
      initExtra = concatStringsSep "\n" ([
        ''setopt APPEND_HISTORY''
        ''setopt HIST_SAVE_NO_DUPS''
        ''setopt HIST_FIND_NO_DUPS''
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

    # Actual Shell Configurations
    home.programs.fish = mkIf (cfg.shell == "fish") {
      enable = true;
      shellAliases = {
        ls = "eza -la --icons --no-user --no-time --git -s type";
        cat = "bat";
      };
      shellInit = ''
        ${mkIf apps.tools.direnv.enable ''
          direnv hook fish | source
        ''}

        zoxide init fish | source

        function , --description 'add software to shell session'
              nix shell nixpkgs#$argv[1..-1]
        end
      '';
    };

    # Enable all if nushell
    home.programs.nushell = mkIf (cfg.shell == "nushell") {
      enable = true;
      shellAliases = config.environment.shellAliases // {ls = "ls";};
      envFile.text = "";
      extraConfig = ''
        $env.config = {
        	show_banner: false,
        }

        def , [...packages] {
            nix shell ($packages | each {|s| $"nixpkgs#($s)"})
        }
      '';
    }; 
  };
}
