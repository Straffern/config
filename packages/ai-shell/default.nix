{ lib, writeTextFile, jq, opencode }:

{ model ? null, systemPrompt ?
  "Generate ONLY the exact shell command needed. No explanations, no markdown, no formatting - just the raw command. DO NOT USE ANY TOOLS."
}:

writeTextFile {
  name = "ai-shell-function";
  text = ''
        # ai - AI-powered command generator for zsh
        # Usage: ai ffmpeg command for extracting audio from video.mp4
        
        ai() {
          # Check if any arguments were provided
          if [[ $# -eq 0 ]]; then
            echo "Error: Please provide a prompt describing the command you need." >&2
            echo "Usage: ai <description of command>" >&2
            echo "Example: ai ffmpeg command for extracting audio from video.mp4" >&2
            return 1
          fi
          
          # Combine all arguments into a single prompt
          local prompt="$*"
          
          # System prompt (configurable via Nix)
          local system_prompt="${systemPrompt}"
          
          # Run opencode with JSON output format
          local output
          output=$(${opencode}/bin/opencode run --format json ${
            lib.optionalString (model != null) ''--model "${model}"''
          } "$system_prompt

    Command needed: ''${prompt}" 2>&1)
          local exit_code=$?
          
          # Check if opencode succeeded
          if [[ $exit_code -ne 0 ]]; then
            echo "Error: OpenCode failed with exit code $exit_code" >&2
            echo "$output" >&2
            return 1
          fi
          
          
          # Check if model used a tool (and warn if it did)
          if echo "$output" | grep -q '"type":"tool_use"'; then
            echo "Warning: Model used a tool despite being instructed not to" >&2
          fi
          
          # Extract command from text event (expects single text event)
          # Process each line separately to handle newline-delimited JSON
          local command
          command=$(printf '%s\n' "$output" | while IFS= read -r line; do
            printf '%s\n' "$line" | ${jq}/bin/jq -r 'select(.type == "text") | .part.text' 2>/dev/null || true
          done | sed -z 's/^[[:space:]]*//;s/[[:space:]]*$//')
          
          # If we got a command, put it in the ZLE buffer
          if [[ -n "$command" ]]; then
            print -z "$command"
          else
            echo "Error: OpenCode returned empty output" >&2
            echo "Raw output: $output" >&2
            return 1
          fi
        }
  '';
}
