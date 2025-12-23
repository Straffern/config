{ pkgs, config, lib, namespace, inputs, ... }:
let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.cli.programs.jj;
  colors = config.lib.stylix.colors; # Access Stylix colors

  jj-helpers-lib = pkgs.writers.writeBash "jj-helpers-lib" ''
    shopt -s -o errexit nounset pipefail

    change_ids() {
      jj log --ignore-working-copy --revisions "$1" --reversed --no-graph --template 'change_id.short() ++ "\n"'
    }

    change_id() {
      declare ids
      ids="$(change_ids "$1")"
      if [ "$(echo "$ids" | wc -l)" -ne 1 ]; then
        echo "invalid revset: $1 should have exactly one revision" >&2
        return 1
      fi
      printf '%s\n' "$ids"
    }

    description() {
      jj log --ignore-working-copy --revisions "$1" --no-graph --template 'description'
    }

    revset() {
      change_ids "$1" | jq --null-input --raw-input --raw-output '
        [inputs] | if length == 0 then "none()" else join("|") end
      '
    }

    escape() {
      if [ "$(printf '%q' "''${1}")" = "''${1}" ]; then
        printf '%s' "''${1}"
      else
        printf "'%s'" "''${1//\'/\'\"\'\"\'}"
      fi
    }

    register_rollback_instructions() {
      local op
      op="$(jj operation log --no-graph --template 'if(self.current_operation(), self.id().short(), "")')"
      trap 'printf '"'"'\x1b[1;33mTo roll back these changes, run:\x1b[0m\n\t\x1b[1;32mjj operation restore %s\x1b[0m\n'"'"' "'"''${op}"'"' EXIT
    }

    log_and_run() {
      printf '\x1b[1;32m$ '
      printf '%s' "$(escape "''${1}")"
      for arg in "''${@:2}"; do printf ' %s' "$(escape "''${arg}")"; done
      printf '\x1b[0m\n'
      "$@"
    }
  '';

in {
  options.${namespace}.cli.programs.jj = with types; {
    enable = mkEnableOption "jujutsu";
    userName = mkOpt (nullOr str) "Alexander Flensborg"
      "The name appearing on the commits";
    email =
      mkOpt (nullOr str) "alex@flensborg.dev" "The email to use with git.";
    alias = mkOpt (nullOr str) "straffern"
      "An alias for your user. Eg. Account name.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ lazyjj jujutsu watchman difftastic inputs.jjui.packages.${pkgs.system}.default asgaard.jj-starship ];

    programs.jujutsu = {
      enable = true;
      settings = {

        fsmonitor.backend = "watchman";
        fsmonitor.watchman.register-snapshot-trigger = true;

        user = {
          email = cfg.email;
          name = cfg.userName;
        };

        ui = {
          default-command = "worklog";
          pager = "delta";
          # diff-editor = "nvim-hunk";
          diff.formatter = "difftastic";
          merge-editor = "vimdiff";

          # show-cryptographic-signatures = true;
        };

        merge-tools.difftastic = {
          program = "${pkgs.difftastic}/bin/difft";
          diff-args = [ "--color=always" "$left" "$right" ];
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
          }; # e.g., #7f00ff for magenta
          "working_copy commit_id" = { underline = true; };
          "diff removed token" = {
            fg = "#${colors.base08}";
            # fg = "#${colors.base05}";
            bg = "#ff0000";
            underline = false;
          }; # e.g., #ff0000 for red
          "diff added token" = {
            fg = "#${colors.base0B}";
            # fg = "#${colors.base05}";
            bg = "#007f00";
            underline = false;
          }; # e.g., #00ff00 for green
        };

        signing = let gitCfg = config.programs.git.settings;
        in {
          backend = "ssh";
          behaviour = if gitCfg.commit.gpgsign then "own" else "never";
          key = gitCfg.user.signingkey;
        };
        revsets = {
          log =
            "@ | ancestors(immutable_heads().., 2) | heads(immutable_heads())";
        };

        aliases = let
          mkExecAlias = program: [ "util" "exec" "--" program ];
          mkBashAlias = name: text:
            mkExecAlias
            (lib.getExe (pkgs.writers.writeBashBin "jj-${name}" text));
        in {
          # create named bookmark at HEAD
          name = [ "bookmark" "create" "-r" "head" ];
          # update bookmark <arg> to point to HEAD
          update = [ "bookmark" "move" "--to" "head" ];
          # pull up the nearest bookmarks to the last described commit
          tug = [ "bookmark" "move" "--from" "curbranch" "--to" "latest" ];

          # push the nearest bookmark
          push = [ "git" "push" "-r" "curbranch" ];

          "ui" = mkExecAlias "${pkgs.jj-fzf}/bin/jj-fzf";

          "worklog" = [ "log" "-r" "(trunk()..@):: | (trunk()..@)-" ];

          # List change IDs of changes in a revset (default '@')
          "change-id" = mkBashAlias "change-id" # bash
            ''
              source ${jj-helpers-lib}

              main() {
                if [ $# -gt 1 ]; then
                  echo "usage: jj change-id [<revset>]" >&2
                  return 1
                fi

                jj log --ignore-working-copy --revisions "''${1-@}" --reversed --no-graph --template 'change_id ++ "\n"'
              }

              main "$@"
            '';

          # List commit IDs of changes in a revset (default '@')
          "commit-id" = mkBashAlias "commit-id" # bash
            ''
              source ${jj-helpers-lib}

              main() {
                if [ $# -gt 1 ]; then
                  echo "usage: jj commit-id [<revset>]" >&2
                  return 1
                fi

                jj log --ignore-working-copy --revisions "''${1-@}" --reversed --no-graph --template 'commit_id ++ "\n"'
              }

              main "$@"
            '';

          # List names of bookmarks pointing to changes in a revset (default '@')
          "bookmark-names" = mkBashAlias "bookmark-names" # bash
            ''
              source ${jj-helpers-lib}

              main() {
                if [ $# -gt 1 ]; then
                  echo "usage: jj bookmark-names [<revset>]" >&2
                  return 1
                fi
                jj log --ignore-working-copy --revisions "''${1-@}" --no-graph --template 'bookmarks.map(|b| b.name() ++ "\n").join("")'
              }

              main "$@"
            '';

          # Run a command at every revision in a revset
          # TODO: replace when `jj run` isn't a stub anymore
          "run-job" = mkBashAlias "run-job" # bash
            ''
              source ${jj-helpers-lib}

              log_lit_command() {
                printf '\x1b[1;32m$ %s\x1b[0m\n' "''${1}"
              }

              usage() {
                echo "usage: jj run-job [jj-flags...] <revset> -- <command> <args>..."
                exit 1
              }

              main() {
                # Collect args before and after --
                local -a jj_args=()
                while [[ $# -gt 0 && "$1" != "--" ]]; do
                  jj_args+=("$1")
                  shift
                done

                [[ "''${1:-}" == "--" ]] || { echo "error: missing -- separator before command" >&2; usage; }
                shift

                [[ $# -ge 1 ]] || { echo "error: no command specified" >&2; usage; }
                [[ ''${#jj_args[@]} -ge 1 ]] || { echo "error: no revset specified" >&2; usage; }

                # Last jj_arg is the revset, rest are flags
                local revset="''${jj_args[-1]}"
                unset 'jj_args[-1]'
                local -a cmd=("$@")

                register_rollback_instructions

                change_ids "''${revset}" | while read -r rev; do
                  log_and_run jj "''${jj_args[@]}" edit "''${rev}"

                  log_lit_command 'cd "$(jj workspace root)"'
                  cd "$(jj --ignore-working-copy workspace root)"

                  log_and_run "''${cmd[@]}"
                done
              }

              main "$@"
            '';

          "flow" = mkBashAlias "flow" # bash
            ''
              source ${jj-helpers-lib}

              # @describe Manage a branch-of-branches for a megamerge workflow
              # @meta require-tools jj

              # @cmd Move to the tip of the flow
              tip() {
                log_and_run jj new 'bookmarks(exact:"flow")'
              }

              # @cmd Manage the set of changes managed by the flow
              # @alias change,c
              changes() { :; }

              # @cmd Add a revision to the changes managed by the flow
              # @arg revset! The revision to add
              changes::add() {
                register_rollback_instructions

                local flow
                flow="$(change_ids 'present(bookmarks(exact:"flow"))')"

                if [ -n "$flow" ]; then
                  log_and_run jj rebase --source 'bookmarks(exact:"flow")' --destination 'all:parents(bookmarks(exact:"flow")) | ('"$argc_revset"')'
                else
                  local old_children new_children flow_commit
                  old_children="$(revset 'children('"$argc_revset"')')"
                  log_and_run jj new --no-edit 'all:'"$argc_revset" --message 'xxx:flow'
                  new_children="$(revset 'children('"$argc_revset"')')"
                  flow_commit="$(change_id '('"$new_children"') ~ ('"$old_children"')')"
                  log_and_run jj bookmark create flow --revision "$flow_commit"
                fi
              }

              # @cmd Remove a revision from the changes managed by the flow
              # @alias rm
              # @arg revset! The revision to remove
              changes::remove() {
                register_rollback_instructions

                local num_parents flow_empty

                # If there are no parents now, we're done
                num_parents="$(change_ids 'parents(present(bookmarks(exact:"flow")))' | wc -l)"
                if [ "$num_parents" -eq 0 ]; then
                  printf '%s\n' 'nothing to do'
                  return
                fi

                # If removing the argument would remove all parents, delete the bookmark
                num_parents="$(change_ids 'parents(bookmarks(exact:"flow")) ~ ('"$argc_revset"')' | wc -l)"
                if [ "$num_parents" -eq 0 ]; then
                  flow_empty="$(change_ids 'bookmarks(exact:"flow") & none() & description(exact:"")')"
                  if [ -n "$flow_empty" ]; then
                    log_and_run jj abandon 'bookmarks(exact:"flow")'
                  fi
                  log_and_run jj bookmark delete flow
                  return
                fi

                # Otherwise, just remove the given parents
                log_and_run jj rebase --source 'bookmarks(exact:"flow")' --destination 'all:parents(bookmarks(exact:"flow")) ~ ('"$argc_revset"')'
              }

              # @cmd Move a change managed by the flow to a different revision
              # @alias mv
              # @arg old! The revision to remove
              # @arg new! The revision to add
              changes::move() {
                register_rollback_instructions
                log_and_run jj rebase --source 'bookmarks(exact:"flow")' --destination 'all:parents(bookmarks(exact:"flow")) ~ ('"$argc_old"') | ('"$argc_new"')'
              }

              # @cmd Rebase all changes managed by the flow onto a destination
              # @arg destination! Revision of the new base for changes
              rebase() {
                register_rollback_instructions
                log_and_run jj rebase --source 'all:roots(('"$argc_destination"')..bookmarks(exact:"flow"))' --destination "$argc_destination"
              }

              # @cmd Push all flow-managed branches
              push() {
                log_and_run jj git push --revisions 'all:trunk()..parents(bookmarks(exact:"flow"))'
              }

              eval "$(${pkgs.argc}/bin/argc --argc-eval "$0" "$@")"
            '';

          # Convenient shorthands.
          d = [ "diff" ];
          s = [ "show" ];
          ll = [ "log" "-T" "builtin_log_detailed" ];
          nt = [ "new" "trunk()" ];

          # Get all open stacks of work.
          open = [ "log" "-r" "open()" ];

          # Better name, IMO.
          credit = [ "file" "annotate" ];

          # Retrunk a series. Typically used as `jj retrunk -s ...`, and notably can be
          # used with open:
          # - jj retrunk -s 'all:roots(open())'
          retrunk = [ "rebase" "-d" "trunk()" ];

          # Retrunk the current stack of work.
          reheat =
            [ "rebase" "-d" "trunk()" "-s" "all:roots(trunk()..stack(@))" ];

          # Assumes the existence of a 'megamerge' bookmark and 'trunk()' resolving
          # properly to a single commit. Then 'jj sandwich xyz' to move xyz into the
          # megamerge in parallel to everything else.
          sandwich = [ "rebase" "-B" "megamerge()" "-A" "trunk()" "-r" ];

          # Take content from any change, and move it into @.
          # - jj consume xyz path/to/file`
          consume = [ "squash" "--into" "@" "--from" ];

          # Eject content from @ into any other change.
          # - jj eject xyz --interactive
          eject = [ "squash" "--from" "@" "--into" ];

        };

        revset-aliases = {
          "head" = "git_head()";
          "latest" = "latest(curbranch..@ ~ subject(exact:'') ~ empty())";

          "bases" = "dev";
          "downstream(x,y)" = "(x::y) & y";
          "branches" = "downstream(trunk(), bookmarks())";
          "heads" = "heads(trunk()::)";
          "leafs" = "branches | heads";
          "curbranch" = "latest(branches::@- & branches)";
          "nextbranch" = "roots(@:: & branchesandheads)";

          # graph utilities
          "symdiff(x, y)" =
            "(x ~ y) | (y ~ x)"; # commits in either x or y, but not both
          "lr(x, y)" =
            "fork_point(x | y)..(x | y)"; # lr(x, y) is what 'git log' calls x...y
          "vee(x, y)" = "fork_point(x | y) | (fork_point(x | y)..(x | y))";

          # work utilities
          "named()" = "bookmarks() | remote_bookmarks() | tags() | trunk()";
          "merged()" = "ancestors(named())";
          "unmerged()" = "~merged()";

          # commit info
          "user(x)" = "author(x) | committer(x)";
          "mine()" = let
            names = [ cfg.userName ];
            emails = [ cfg.email ];
            toAuthor = x: "author(exact:${builtins.toJSON x})";
          in builtins.concatStringsSep " | "
          (builtins.map toAuthor (emails ++ names));

          # By default, show the repo trunk, the remote bookmarks, and all remote tags. We
          # don't want to change these in most cases, but in some repos it's useful.
          "immutable_heads()" =
            "present(trunk()) | remote_bookmarks() | tags()";
          # Useful to ignore this, in many repos. For repos like `jj` these are
          # consistently populated with a bunch of auto-generated commits, so ignoring it
          # is often nice.
          "gh_pages()" = "ancestors(remote_bookmarks(exact:'gh-pages'))";

          # trunk() by default resolves to the latest 'main'/'master' remote bookmark. May
          # require customization for repos like nixpkgs.
          "trunk()" =
            "latest((present(main) | present(master)) & remote_bookmarks())";

          # Private and WIP commits that should never be pushed anywhere. Often part of
          # work-in-progress merge stacks.
          "wip()" = "description(glob-i:'^wip:*')";
          "private()" =
            "description(regex:'^[xX]+:') | description(glob:'private:*')";
          "blacklist()" = "wip() | private()";
          # stack(x, n) is the set of mutable commits reachable from 'x', with 'n'
          # parents. 'n' is often useful to customize the display and return set for
          # certain operations. 'x' can be used to target the set of 'roots' to traverse,
          # e.g. @ is the current stack.
          "stack()" = "ancestors(reachable(@, mutable()), 2)";
          "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
          "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";

          # The current set of "open" works. It is defined as:
          #
          # - given the set of commits not in trunk, that are written by me,
          # - calculate the given stack() for each of those commits
          #
          # n = 1, meaning that nothing from `trunk()` is included, so all resulting
          # commits are mutable by definition.
          "open()" = "stack(trunk().. & mine(), 1)";

          # the set of 'ready()' commits. defined as the set of open commits, but nothing
          # that is blacklisted or any of their children.
          #
          # often used with gerrit, which you can use to submit whole stacks at once:
          #
          # - jj gerrit send -r 'ready()' --dry-run
          "ready()" = "open() ~ blacklist()::";

          # Find the latest megamerge. Mostly useful in combination with other aliases.
          # FIXME: I wish there was a way to assert that there should only be a resultset
          # of size 1 for this, because this assumes that there's only one megamerge on
          # your current path to the root.
          "megamerge()" = "reachable(stack(), merges())";

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
          git_push_bookmark =
            lib.mkDefault ''"${cfg.alias}/push-" ++ change_id.short()'';
        };

        template-aliases = {
          "format_short_signature(signature)" = "signature.email().local()";
        };

        git = {
          auto-local-bookmark = true;
          sign-on-push = true;
          private-commits = lib.mkDefault "blacklist()";
          write-change-id-header = true;
        };

      };
    };

    ${namespace}.cli.shells.zsh.initContent = ''
      autoload -U compinit
      compinit
      source <(jj util completion zsh)
    '';
  };
}
