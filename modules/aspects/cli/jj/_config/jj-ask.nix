{ pkgs, ... }:
pkgs.writeTextFile {
  name = "jj-ask-function";
  text = ''
            # jj? - AI-powered jj command generator for zsh
            # Usage: jj? show commits on my branch that are not in main

            function 'jj?' {
              emulate -L zsh
              setopt local_options no_xtrace

              local piped_input=""
              if [[ ! -t 0 ]]; then
                piped_input=$(cat)
              fi

              if [[ $# -eq 0 && -z "$piped_input" ]]; then
                echo "Error: Please describe the jj command you need." >&2
                echo "Usage: jj? <description of jj command>" >&2
                echo "       echo 'context' | jj? <description of jj command>" >&2
                echo "Example: jj? commits on my branch that are not in main" >&2
                return 1
              fi

              local prompt="$*"
              if [[ -n "$piped_input" ]]; then
                if [[ -n "$prompt" ]]; then
                  prompt="$prompt

            Additional context:
            $piped_input"
                else
                  prompt="$piped_input"
                fi
              fi

              if ! command -v pi >/dev/null 2>&1; then
                echo "Error: pi CLI is not available in PATH" >&2
                return 1
              fi
              if ! command -v jj >/dev/null 2>&1; then
                echo "Error: jj is not available in PATH" >&2
                return 1
              fi

              local revsets filesets
              revsets=$(command jj --no-pager --color never help -k revsets 2>/dev/null) || revsets=""
              filesets=$(command jj --no-pager --color never help -k filesets 2>/dev/null) || filesets=""

              local system_prompt
              system_prompt=$(cat <<EOF
    You generate one jj command for the current repository.

    Use tools when you need more detail. Prefer \`jj help <subcommand>\` for command-specific syntax, flags, and examples. Do not invent flags.

    Installed revset language:
    $revsets

    Installed fileset language:
    $filesets

    The last message you emit must be exactly one jj command. No markdown, no explanation, no quotes, no surrounding text. The command must start with jj.
    EOF
    )

              local -a pi_args
              pi_args=(
                --print
                --mode text
                --system-prompt "$system_prompt"
                --model "openai-codex/gpt-5.6-luna"
              )
              local output
              output=$(pi "''${pi_args[@]}" "Command needed: ''${prompt}")
              local exit_code=$?
              if [[ $exit_code -ne 0 ]]; then
                echo "Error: pi failed with exit code $exit_code" >&2
                return 1
              fi

              local command=""
              local line
              while IFS= read -r line; do
                line="''${line#"''${line%%[![:space:]]*}"}"
                line="''${line%"''${line##*[![:space:]]}"}"
                [[ -z "$line" ]] && continue
                [[ "$line" == '```'* ]] && continue
                if [[ "$line" == jj[[:space:]]* || "$line" == jj ]]; then
                  command="$line"
                fi
              done <<< "$output"

              if [[ -z "$command" ]]; then
                command="$output"
                command="''${command#"''${command%%[![:space:]]*}"}"
                command="''${command%"''${command##*[![:space:]]}"}"
              fi

              if [[ -n "$command" ]]; then
                print -z "$command"
              else
                echo "Error: pi returned empty output" >&2
                return 1
              fi
            }
            alias -- 'jj?'='noglob jj?'
  '';
}
