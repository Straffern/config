# JJ command aliases - both simple shorthands and complex bash-based workflows
{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.${namespace}.cli.programs.jj;

  # Shared bash utilities for jj scripts
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

  # Helper to create bash-based jj aliases
  mkExecAlias = program: ["util" "exec" "--" program];
  mkBashAlias = name: text:
    mkExecAlias
    (lib.getExe (pkgs.writers.writeBashBin "jj-${name}" text));
in {
  config = mkIf cfg.enable {
    programs.jujutsu.settings.aliases = {
      # ══════════════════════════════════════════════════════════════════════════
      # Simple bookmark/branch shorthands
      # ══════════════════════════════════════════════════════════════════════════

      # Create named bookmark at HEAD
      name = ["bookmark" "create" "-r" "head"];
      # Update bookmark <arg> to point to HEAD
      update = ["bookmark" "move" "--to" "head"];
      # Pull up the nearest bookmarks to the last described commit
      tug = ["bookmark" "move" "--from" "curbranch" "--to" "latest"];
      # Push the nearest bookmark
      push = ["git" "push" "-r" "curbranch"];

      # ══════════════════════════════════════════════════════════════════════════
      # Log/view shorthands
      # ══════════════════════════════════════════════════════════════════════════

      worklog = ["log" "-r" "worklog()"];
      d = ["diff"];
      s = ["show"];
      ll = ["log" "-T" "builtin_log_detailed"];
      nt = ["new" "trunk()"];

      # Full branch view from trunk to @ including descendants
      branch = ["log" "-r" "trunk()..@ | @::"];
      # Get all open stacks of work
      open = ["log" "-r" "open()"];
      # Better name, IMO
      credit = ["file" "annotate"];

      # Log toggle aliases - switch between compact and verbose views
      llc = ["log" "-r" "@ | @-"]; # Compact: shows only @ and immediate context
      llf = ["log" "-r" "all()"]; # Full: shows everything

      # ══════════════════════════════════════════════════════════════════════════
      # Rebase/navigation shorthands
      # ══════════════════════════════════════════════════════════════════════════

      # Retrunk a series. Typically used as `jj retrunk -s ...`
      # Can be used with open: `jj retrunk -s 'all:roots(open())'`
      retrunk = ["rebase" "-d" "trunk()"];
      # Retrunk the current stack of work
      reheat = ["rebase" "-d" "trunk()" "-s" "roots(trunk()..stack(@))"];
      # Assumes 'megamerge' bookmark and trunk(). `jj sandwich xyz` moves xyz into megamerge
      sandwich = ["rebase" "-B" "megamerge()" "-A" "trunk()" "-r"];

      # ══════════════════════════════════════════════════════════════════════════
      # Squash/content movement shorthands
      # ══════════════════════════════════════════════════════════════════════════

      # Take content from any change, and move it into @
      # Usage: `jj consume xyz path/to/file`
      consume = ["squash" "--into" "@" "--from"];
      # Eject content from @ into any other change
      # Usage: `jj eject xyz --interactive`
      eject = ["squash" "--from" "@" "--into"];

      # ══════════════════════════════════════════════════════════════════════════
      # Bash-based aliases (complex workflows)
      # ══════════════════════════════════════════════════════════════════════════

      # Log my commits after a given date string
      "after" =
        mkBashAlias "after" # bash
        
        ''
          source ${jj-helpers-lib}

          main() {
            if [ $# -lt 1 ]; then
              echo "usage: jj after <date pattern>" >&2
              return 1
            fi

            local when="$*"
            when="''${when//\"/\\\"}"
            jj log -r "mine() & author_date(after:\"''${when}\")"
          }

          main "$@"
        '';

      # Log my commits before a given date string
      "before" =
        mkBashAlias "before" # bash
        
        ''
          source ${jj-helpers-lib}

          main() {
            if [ $# -lt 1 ]; then
              echo "usage: jj before <date pattern>" >&2
              return 1
            fi

            local when="$*"
            when="''${when//\"/\\\"}"
            jj log -r "mine() & author_date(before:\"''${when}\")"
          }

          main "$@"
        '';

      # List change IDs of changes in a revset (default '@')
      "change-id" =
        mkBashAlias "change-id" # bash
        
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
      "commit-id" =
        mkBashAlias "commit-id" # bash
        
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
      "bookmark-names" =
        mkBashAlias "bookmark-names" # bash
        
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
      "run-job" =
        mkBashAlias "run-job" # bash
        
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

      # ══════════════════════════════════════════════════════════════════════════
      # Flow - Megamerge workflow manager
      # ══════════════════════════════════════════════════════════════════════════

      "flow" =
        mkBashAlias "flow" # bash
        
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
              log_and_run jj rebase --source 'bookmarks(exact:"flow")' --destination 'parents(bookmarks(exact:"flow")) | ('"$argc_revset"')'
            else
              local old_children new_children flow_commit
              old_children="$(revset 'children('"$argc_revset"')')"
              log_and_run jj new --no-edit '"$argc_revset"' --message 'xxx:flow'
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
            log_and_run jj rebase --source 'bookmarks(exact:"flow")' --destination 'parents(bookmarks(exact:"flow")) ~ ('"$argc_revset"')'
          }

          # @cmd Move a change managed by the flow to a different revision
          # @alias mv
          # @arg old! The revision to remove
          # @arg new! The revision to add
          changes::move() {
            register_rollback_instructions
            log_and_run jj rebase --source 'bookmarks(exact:"flow")' --destination 'parents(bookmarks(exact:"flow")) ~ ('"$argc_old"') | ('"$argc_new"')'
          }

          # @cmd Rebase all changes managed by the flow onto a destination
          # @arg destination! Revision of the new base for changes
          rebase() {
            register_rollback_instructions
            log_and_run jj rebase --source 'roots(('"$argc_destination"')..bookmarks(exact:"flow"))' --destination "$argc_destination"
          }

          # @cmd Push all flow-managed branches
          push() {
            log_and_run jj git push --revisions 'trunk()..parents(bookmarks(exact:"flow"))'
          }

          eval "$(${pkgs.argc}/bin/argc --argc-eval "$0" "$@")"
        '';

      # ══════════════════════════════════════════════════════════════════════════
      # Workspace add with repo hooks support
      # Creates workspaces at <repo-root>/.workspaces/<name>
      # Executes <repo-root>/.jj/hooks/post-workspace-add if it exists
      # ══════════════════════════════════════════════════════════════════════════

      "wa" =
        mkBashAlias "wa" # bash
        
        ''
          source ${jj-helpers-lib}

          main() {
            if [ $# -lt 1 ]; then
              echo "usage: jj wa <workspace-name> [jj workspace add args...]" >&2
              return 1
            fi

            local name="$1"; shift

            # Get true repo root (handles running from workspaces)
            # - Workspaces have .jj/repo as a FILE containing path to shared repo
            # - Main repos have .jj/repo as a DIRECTORY
            local root
            if [ -f "$JJ_WORKSPACE_ROOT/.jj/repo" ]; then
              # We're in a workspace - .jj/repo contains path like /path/to/main/.jj/repo
              root=$(dirname "$(dirname "$(cat "$JJ_WORKSPACE_ROOT/.jj/repo")")")
            else
              # We're in the main repo
              root="$JJ_WORKSPACE_ROOT"
            fi

            local dest="$root/.workspaces/$name"

            log_and_run jj workspace add "$dest" "$@"

            # Execute repo-specific hook if it exists
            local hook="$root/.jj/hooks/post-workspace-add"
            if [ -x "$hook" ]; then
              log_and_run "$hook" "$dest"
            elif [ -f "$hook" ]; then
              log_and_run bash "$hook" "$dest"
            fi
          }

          main "$@"
        '';
    };
  };
}
