{
  writeShellScriptBin,
  hyprland,
  procps,
  coreutils,
}:
writeShellScriptBin "hyprlock-recover" ''
    set -euo pipefail

    INSTANCE=0
    MODE=relaunch

    usage() {
      cat <<EOF
  hyprlock-recover - recover a wedged Hyprland lockscreen

  Usage:
    hyprlock-recover [--instance N] [relaunch|hard-relaunch]

  Commands:
    relaunch       set allow_session_lock_restore and start hyprlock
    hard-relaunch  kill existing hyprlock, then relaunch

  Options:
    -i, --instance N  Hyprland instance index or signature (default: 0)
    -h, --help        Show this help
  EOF
    }

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -i|--instance)
          INSTANCE="$2"
          shift 2
          ;;
        relaunch|hard-relaunch)
          MODE="$1"
          shift
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown argument: $1" >&2
          usage >&2
          exit 1
          ;;
      esac
    done

    if [[ "$MODE" == "hard-relaunch" ]]; then
      ${procps}/bin/pkill -9 -x hyprlock || true
      ${coreutils}/bin/sleep 0.2
    fi

    ${hyprland}/bin/hyprctl --instance "$INSTANCE" keyword misc:allow_session_lock_restore 1
    ${hyprland}/bin/hyprctl --instance "$INSTANCE" dispatch exec hyprlock
''
