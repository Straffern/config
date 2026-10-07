{
  den,
  inputs,
  ...
}: let
  jjui = inputs':
    inputs'.jjui.packages.jjui.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./_patches/jjui-ai-revset.patch];
    });
  jj-revset-ai = inputs': pkgs: model:
    pkgs.callPackage ./_package/jj-revset-ai.nix {
      inherit model;
      jujutsu = inputs'.unstable.legacyPackages.jujutsu;
      pi = inputs'.llm-agents.packages.pi;
    };
  lumen = pkgs: pkgs.callPackage ./_package/lumen.nix {src = inputs.lumen;};
  jj-starship = pkgs: pkgs.callPackage ./_package/jj-starship.nix {};
  ji = inputs': pkgs:
    pkgs.callPackage ./_package/ji.nix {
      jujutsu = inputs'.unstable.legacyPackages.jujutsu;
      rustPlatform = inputs'.unstable.legacyPackages.rustPlatform;
    };
in {
  flake-file.inputs = {
    lumen.url = "github:jnsahaj/lumen/v2.32.0";
    jjui = {
      url = "github:idursun/jjui/v0.10.11";
      inputs.nixpkgs.follows = "unstable";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "unstable";
    };
  };
  den.aspects.cli = {
    lumen = {
      homeManager = {pkgs, ...}: {
        home.packages = [(lumen pkgs)];
      };
    };

    jj = {
      includes = [
        den.aspects.cli.lumen
      ];
      nixos.environment.etc."watchman.json".text = builtins.toJSON {
        root_files = [".jj"];
        enforce_root_files = true;
        # Every jj command adds a root that persists across restarts; drop unused ones.
        idle_reap_age_seconds = 86400;
      };
      homeManager = {
        config,
        inputs',
        lib,
        pkgs,
        ...
      }: let
        models = config.dotfiles.ai.models;
        revsetAi = jj-revset-ai inputs' pkgs models.jjRevset;
      in {
        options.dotfiles.ai.models = {
          jjAsk = lib.mkOption {
            type = lib.types.str;
            default = "openai-codex/gpt-6.1-sol:low";
            description = "pi model used by the `jj?` zsh command.";
          };
          jjRevset = lib.mkOption {
            type = lib.types.str;
            default = "openai-codex/gpt-6.1-sol:low";
            description = "pi model used by jj-revset-ai (jjui AI revsets).";
          };
        };

        config = {
          home.packages = [
            inputs'.unstable.legacyPackages.jujutsu
            pkgs.watchman
            pkgs.difftastic
            (jjui inputs')
            revsetAi
            (jj-starship pkgs)
          ];

          xdg.configFile."jjui/config.toml".text = ''
            [revset]
            ai_command = "${revsetAi}/bin/jj-revset-ai"
          '';

          programs.zsh.initContent = lib.mkAfter ''
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

            source ${import ./_config/jj-ask.nix {
              inherit pkgs;
              model = models.jjAsk;
            }}
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
            package = inputs'.unstable.legacyPackages.jujutsu;
            settings = {
              inherit ((import ./_config/aliases.nix {inherit pkgs lib;})) aliases;
              revset-aliases = import ./_config/revsets.nix {
                userName = "Alexander Flensborg";
                email = "alex@flensborg.dev";
              };
              fsmonitor.backend = "watchman";
              fsmonitor.watchman.register-snapshot-trigger = false;

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
                  behavior =
                    if signCommits
                    then "drop"
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
      };

      packages = {pkgs, ...}: {
        jj-starship = jj-starship pkgs;
      };
    };

    ji = {
      includes = [den.aspects.cli.jj];
      homeManager = {
        inputs',
        lib,
        pkgs,
        ...
      }: let
        package = ji inputs' pkgs;
        zshHook = pkgs.runCommand "ji-zsh-hook" {} ''
          ${lib.getExe' package "ji"} config shell init zsh > "$out"
        '';
      in {
        home.packages = [
          package
          pkgs.wl-clipboard
        ];
        programs.zsh.initContent = lib.mkAfter ''
          source ${zshHook}
        '';
      };
    };
  };
}
