{
  lib,
  writeTextFile,
}: {
  model ? null,
  systemPrompt ? "Generate ONLY the exact shell command needed. No explanations, no markdown, no formatting - just the raw command. DO NOT USE ANY TOOLS.",
}:
writeTextFile {
  name = "ai-shell-function";
  text = ''
                # ai - AI-powered command generator for zsh
                # Usage: ai ffmpeg command for extracting audio from video.mp4

                ai() {
                  # Read piped input if available
                  local piped_input=""
                  if [[ ! -t 0 ]]; then
                    piped_input=$(cat)
                  fi

                  # Check if any arguments were provided
                  if [[ $# -eq 0 && -z "$piped_input" ]]; then
                    echo "Error: Please provide a prompt describing the command you need." >&2
                    echo "Usage: ai <description of command>" >&2
                    echo "       echo 'context' | ai <description of command>" >&2
                    echo "Example: ai ffmpeg command for extracting audio from video.mp4" >&2
                    echo "Example: jj diff | ai explain this diff" >&2
                    return 1
                  fi

                  # Combine all arguments into a single prompt
                  local prompt="$*"

                  # Append piped input as additional context if present
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

                  # System prompt (configurable via Nix)
                  local system_prompt="${systemPrompt}"

                  # Build pi arguments
                  local -a pi_args
                  pi_args=(
                    --print
                    --mode text
                    --no-tools
                    --system-prompt "$system_prompt"
                  )

    ${lib.optionalString (model != null) ''
      pi_args+=(--model "${model}")
    ''}

                  # Run pi in non-interactive mode
                  local output
                  output=$(pi "''${pi_args[@]}" "Command needed: ''${prompt}" 2>&1)
                  local exit_code=$?

                  # Check if pi succeeded
                  if [[ $exit_code -ne 0 ]]; then
                    echo "Error: pi failed with exit code $exit_code" >&2
                    echo "$output" >&2
                    return 1
                  fi

                  # Trim output to the command text
                  local command="$output"
                  command="''${command#"''${command%%[![:space:]]*}"}"
                  command="''${command%"''${command##*[![:space:]]}"}"

                  # If we got a command, put it in the ZLE buffer
                  if [[ -n "$command" ]]; then
                    print -z "$command"
                  else
                    echo "Error: pi returned empty output" >&2
                    echo "Raw output: $output" >&2
                    return 1
                  fi
                }
  '';
}
