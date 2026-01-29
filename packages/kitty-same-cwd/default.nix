{
  pkgs,
  lib,
  ...
}:
pkgs.writeShellApplication {
  name = "kitty-same-cwd";
  runtimeInputs = with pkgs; [
    jq
    kitty
    procps # for pgrep
  ];
  text = ''
    # Get CWD from focused kitty window and open new kitty there
    # Requires: hyprctl (from Hyprland), kitty remote control enabled

    FOCUSED=$(hyprctl activewindow -j 2>/dev/null)

    if [[ -z "$FOCUSED" || "$FOCUSED" == "null" ]]; then
      # No focused window, just open kitty
      kitty &
      exit 0
    fi

    FOCUSED_CLASS=$(echo "$FOCUSED" | jq -r '.class // empty')
    FOCUSED_PID=$(echo "$FOCUSED" | jq -r '.pid // empty')

    if [[ "$FOCUSED_CLASS" == "kitty" && -n "$FOCUSED_PID" ]]; then
      # Try kitty remote control first (most accurate)
      CWD=$(kitty @ --to unix:/tmp/kitty ls 2>/dev/null | \
        jq -r --argjson pid "$FOCUSED_PID" \
        '[.[] | .tabs[]? | .windows[]? | select(.foreground_processes[]?.pid == $pid or .pid == $pid)] | .[0].cwd // empty' 2>/dev/null)

      # Fallback: check child shell process via /proc
      if [[ -z "$CWD" || ! -d "$CWD" ]]; then
        CHILD_PID=$(pgrep -P "$FOCUSED_PID" 2>/dev/null | head -1)
        if [[ -n "$CHILD_PID" ]]; then
          CWD=$(readlink "/proc/$CHILD_PID/cwd" 2>/dev/null)
        fi
      fi

      # Final fallback: parent process CWD
      if [[ -z "$CWD" || ! -d "$CWD" ]]; then
        CWD=$(readlink "/proc/$FOCUSED_PID/cwd" 2>/dev/null)
      fi

      if [[ -n "$CWD" && -d "$CWD" ]]; then
        kitty --directory "$CWD" &
      else
        kitty &
      fi
    else
      # Not a kitty window, just open kitty
      kitty &
    fi
  '';

  meta = with lib; {
    description = "Open new kitty terminal in the same directory as the focused kitty window";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
