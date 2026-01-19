{
  writeShellScriptBin,
  fzf,
  ...
}:
writeShellScriptBin "clipy" ''
  #!/usr/bin/env bash

  # Determine the directory to search in: current directory if no argument, otherwise the provided directory
  if [ $# -eq 0 ]; then
    dir="."
  else
    dir="$1"
  fi

  # Change to the specified directory, exit if it fails (e.g., directory doesn't exist)
  cd "$dir" || exit 1

  # Use find to list all files recursively, pipe to fzf, and process the output directly
  find . -type f -print0 | ${fzf}/bin/fzf --read0 --multi --print0 --preview "cat {}" | {
    # Initialize an empty string to accumulate output
    output=""
    # Read null-terminated input from fzf
    while IFS= read -r -d ''' file; do
      # Append the relative path and content to the output string
      output+="File: $file"$'\n'
      output+=$(cat "$file")$'\n'
      output+="---"$'\n'
    done
    # Check if any output was generated (i.e., files were selected)
    if [ -n "$output" ]; then
      # Pipe the output to wl-copy
      printf '%s' "$output" | wl-copy
      echo "Copied to clipboard"
    else
      echo "No files selected"
    fi
  }
''
