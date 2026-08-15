{
  den,
  inputs,
  ...
}: let
  jjui = inputs': inputs'.jjui.packages.jjui;
  ww = inputs': inputs'.ww.packages.default;
  lumen = pkgs: pkgs.callPackage ./_package/lumen.nix {src = inputs.lumen;};
  jj-starship = pkgs: pkgs.callPackage ./_package/jj-starship.nix {};
  jj-ryu = pkgs: pkgs.callPackage ./_package/jj-ryu.nix {};
in {
  flake-file.inputs = {
    lumen.url = "github:jnsahaj/lumen/v2.22.0";
    ww.url = "github:omihirofumi/ww";
    jjui = {
      url = "github:idursun/jjui/v0.10.7";
      inputs.nixpkgs.follows = "unstable";
    };
  };
  den.aspects.cli = {
    lumen = {
      homeManager = {pkgs, ...}: {
        home.packages = [(lumen pkgs)];
      };
    };

    ww = {
      homeManager = {inputs', ...}: {
        home.packages = [(ww inputs')];
      };
    };

    jj = {
      includes = [
        den.aspects.cli.lumen
        den.aspects.cli.ww
      ];
      homeManager = {
        config,
        inputs',
        lib,
        pkgs,
        ...
      }: {
        home.packages = [
          pkgs.jujutsu
          pkgs.watchman
          pkgs.difftastic
          (jjui inputs')
          (jj-starship pkgs)
          (jj-ryu pkgs)
        ];

        programs.zsh.initContent = lib.mkAfter ''
          # ww - jj workspace wrapper
          eval "$(ww init zsh)"

          # jj - route `jj help flow ...` to the flow wrapper without changing
          # other help or command invocations.
          jj() {
            emulate -L zsh
            if [[ ''${1-} == help && ''${2-} == flow ]]; then
              shift 2
              command jj flow "$@" --help
            else
              command jj "$@"
            fi
          }
        '';

        xdg.configFile."zsh/completions/_ww".source = pkgs.runCommand "ww-zsh-completion" {} ''
          ${lib.getExe (ww inputs')} completion zsh > $out
        '';

        programs.starship.settings = {
          custom.jj = {
            command = "${jj-starship pkgs}/bin/jj-starship";
            when = "jj-starship detect";
          };
          git_branch.disabled = false;
          git_status.disabled = false;
        };

        programs.jujutsu = {
          enable = true;
          settings = {
            aliases = (import ./_config/aliases.nix {inherit pkgs lib;}).aliases;
            revset-aliases = import ./_config/revsets.nix {
              userName = "Alexander Flensborg";
              email = "alex@flensborg.dev";
            };
            fsmonitor.backend = "watchman";
            fsmonitor.watchman.register-snapshot-trigger = true;

            user = {
              email = "alex@flensborg.dev";
              name = "Alexander Flensborg";
            };

            ui = {
              default-command = "worklog";
              pager = "delta";
              diff-editor = [
                "nvim"
                "-c"
                "DiffEditor $left $right $output"
              ];
              diff.formatter = [
                "difft"
                "--color=always"
                "$left"
                "$right"
              ];
              merge-editor = "vimdiff";

              # show-cryptographic-signatures = true;
            };

            merge-tools.difftastic = {
              program = "${pkgs.difftastic}/bin/difft";
              diff-args = [
                "--color=always"
                "$left"
                "$right"
              ];
            };
            merge-tools.vimdiff = {
              merge-args = [
                "-f"
                "-d"
                "$output"
                "-M"
                "$left"
                "$base"
                "$right"
                "-c"
                "wincmd J"
                "-c"
                "set modifiable"
                "-c"
                "set write"
              ];
              program = "nvim";
              merge-tool-edits-conflict-markers = true;
            };

            colors = {
              commit_id = {
                # fg = "#${colors.base0A}";
                fg = "#0000ff";
                # bg = "#00008f";
                bold = true;
              }; # e.g., #00008f for blue
              change_id = {
                # fg = "#${colors.base0E}";
                fg = "#7f00ff";
                # bg = "#7f00ff";
                italic = true;
                bold = true;
              }; # e.g., #7f00ff for magenta
              "working_copy commit_id" = {
                underline = true;
              };
              "diff removed token" = {
                # bg = "#${colors.base08}";
                # fg = "#${colors.base05}";
                fg = "#ff0000";
                underline = true;
              }; # e.g., #ff0000 for red
              "diff added token" = {
                # bg = "#${colors.base0B}";
                # fg = "#${colors.base05}";
                fg = "#007f00";
                underline = true;
              }; # e.g., #00ff00 for green
            };

            signing = let
              gitCfg = config.programs.git.settings;
              signCommits = gitCfg.commit.gpgsign or false;
            in
              {
                backend = "ssh";
                behaviour =
                  if signCommits
                  then "own"
                  else "never";
              }
              // lib.optionalAttrs signCommits {
                key = gitCfg.user.signingkey;
              };

            revsets = {
              # Smart log revset showing your work with full context:
              # - @: current working copy
              # - trunk()..@: full path from trunk to your work (with ancestors for context)
              # - heads(trunk()): all branch heads for orientation
              log = "present(@) | ancestors(immutable_heads().., 2) | heads(immutable_heads())";
            };

            templates = {
              draft_commit_description = ''
                concat(
                  description,
                  surround(
                    "\nJJ: Files:\n", "",
                    indent("JJ:     ", diff.summary()),
                  ),
                  "\n",
                  "JJ: ignore-rest\n",
                  diff.git(),
                )
              '';
              git_push_bookmark = lib.mkDefault ''"straffern/push-" ++ change_id.short()'';
            };

            template-aliases = {
              "format_short_signature(signature)" = "signature.email().local()";

              # Terminal hyperlinks
              "hyperlink(url, text)" = ''
                concat(
                  raw_escape_sequence("\e]8;;" ++ url ++ "\e\\"),
                  text,
                  raw_escape_sequence("\e]8;;\e\\")
                )
              '';
              "github_url(change_id)" = ''
                "https://github.com/straffern/.dotfiles/pull/" ++ change_id.short()
              '';
            };

            git = {
              sign-on-push = true;
              private-commits = lib.mkDefault "blacklist()";
              write-change-id-header = true;
            };

            remotes.origin.auto-track-bookmarks = "glob:straffern/*";
          };
        };
      };

      packages = {pkgs, ...}: {
        jj-ryu = jj-ryu pkgs;
        jj-starship = jj-starship pkgs;
      };
    };
  };
}
