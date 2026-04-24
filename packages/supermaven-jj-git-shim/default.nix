{
  writeShellApplication,
  git,
  gnugrep,
  jujutsu,
  ...
}:
writeShellApplication {
  name = "git";
  runtimeInputs = [
    git
    gnugrep
    jujutsu
  ];
  text = ''
    real_git=${git}/bin/git

    jj_root=$(jj root 2>/dev/null) || exec "$real_git" "$@"

    # Colocated jj repos already satisfy Supermaven's Git queries. Only pure jj
    # workspaces need translation, keeping normal Git repos and child processes untouched.
    if [[ -e "$jj_root/.git" && -z "''${SUPERMAVEN_JJ_SHIM:-}" ]]; then
      exec "$real_git" "$@"
    fi

    if [[ "$1" == "rev-parse" && "$2" == "HEAD" ]]; then
      jj log --no-graph -r @ -T 'commit_id ++ "\n"'
      exit 0
    fi

    if [[ "$1" == "log" && "$2" == "--pretty=format:%H" && "$3" == "--first-parent" && "$4" == --max-count=* ]]; then
      n=''${4#--max-count=}
      if [[ "$n" -gt 0 ]]; then
        # Supermaven asks for 41 commits and treats receiving all 41 as
        # ParentCommitLimitExceeded. Git can return 41, but for jj workspaces
        # the useful signal is "up to 40 parents from this active workspace".
        n=$((n - 1))
      fi
      if [[ -n "''${GIT_DIR:-}" ]]; then
        exec "$real_git" log --pretty=format:%H --first-parent --max-count="$n" "''${5:-@}"
      fi
      rev=''${5:-@}
      count=0
      while [[ -n "$rev" && "$rev" != "0000000000000000000000000000000000000000" && "$count" -lt "$n" ]]; do
        echo "$rev"
        parent_output=$(jj log --no-graph -r "$rev-" -T 'commit_id ++ "\n"')
        rev=
        while IFS= read -r parent; do
          if [[ -n "$parent" && "$parent" != "0000000000000000000000000000000000000000" ]]; then
            rev=$parent
            break
          fi
        done <<< "$parent_output"
        count=$((count + 1))
      done
      exit 0
    fi

    if [[ "$1" == "diff-tree" && "$2" == "--name-only" && "$3" == "--no-commit-id" && "$4" == "-r" ]]; then
      if [[ -n "''${GIT_DIR:-}" ]]; then
        exec "$real_git" "$@"
      fi
      from=$5
      to=$6
      if [[ -z "$from" && -n "$to" ]]; then
        jj file list -r "$to"
        exit 0
      fi
      if [[ -n "$from" && -z "$to" ]]; then
        jj file list -r "$from"
        exit 0
      fi
      jj diff --from "$from" --to "$to" --name-only
      exit 0
    fi

    if [[ "$1" == "ls-tree" && "$2" == "-r" && "$3" == "--name-only" ]]; then
      if [[ -n "''${GIT_DIR:-}" ]]; then
        exec "$real_git" "$@"
      fi
      jj file list -r "$4"
      exit 0
    fi

    if [[ "$1" == "cat-file" && "$2" == "blob" ]]; then
      if [[ -n "''${GIT_DIR:-}" ]]; then
        exec "$real_git" "$@"
      fi
      spec=$3
      rev=''${spec%%:*}
      path=''${spec#*:}
      jj file show -r "$rev" "$path"
      exit 0
    fi

    exec "$real_git" "$@"
  '';
}
