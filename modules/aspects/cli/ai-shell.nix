{den, ...}: let
  ai-shell = pkgs: model:
    pkgs.writeTextFile {
      name = "ai-shell-function";
      text = ''
        # ai - AI-powered command generator for zsh
        # Usage: ai ffmpeg command for extracting audio from video.mp4

        ai() {
          local piped_input=""
          if [[ ! -t 0 ]]; then
            piped_input=$(cat)
          fi

          if [[ $# -eq 0 && -z "$piped_input" ]]; then
            echo "Error: Please provide a prompt describing the command you need." >&2
            echo "Usage: ai <description of command>" >&2
            echo "       echo 'context' | ai <description of command>" >&2
            echo "Example: ai ffmpeg command for extracting audio from video.mp4" >&2
            echo "Example: jj diff | ai explain this diff" >&2
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

          local system_prompt="Generate ONLY the exact shell command needed. No explanations, no markdown, no formatting - just the raw command. DO NOT USE ANY TOOLS."
          local -a pi_args
          pi_args=(
            --print
            --mode text
            --no-tools
            --system-prompt "$system_prompt"
            --model "${model}"
          )

          local output
          output=$(pi "''${pi_args[@]}" "Command needed: ''${prompt}" 2>&1)
          local exit_code=$?
          if [[ $exit_code -ne 0 ]]; then
            echo "Error: pi failed with exit code $exit_code" >&2
            echo "$output" >&2
            return 1
          fi

          local command="$output"
          command="''${command#"''${command%%[![:space:]]*}"}"
          command="''${command%"''${command##*[![:space:]]}"}"
          if [[ -n "$command" ]]; then
            print -z "$command"
          else
            echo "Error: pi returned empty output" >&2
            echo "Raw output: $output" >&2
            return 1
          fi
        }
      '';
    };
in {
  den.aspects.cli.ai-shell.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.ai.models.shell = lib.mkOption {
      type = lib.types.str;
      default = "openai-codex/gpt-6.1-sol:low";
      description = "pi model used by the `ai` zsh command.";
    };
    config.programs.zsh.initContent = ''
      source ${ai-shell pkgs config.dotfiles.ai.models.shell}
    '';
  };
}
