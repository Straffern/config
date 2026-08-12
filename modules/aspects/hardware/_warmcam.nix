{
  writeShellScriptBin,
  ffmpeg,
  coreutils,
}:
writeShellScriptBin "warmcam" ''
  set -euo pipefail

  # PID file location
  PIDFILE="''${XDG_RUNTIME_DIR:-/tmp}/warmcam.pid"

  # Default configuration
  INPUT_DEVICE="''${WARMCAM_INPUT:-/dev/video2}"
  OUTPUT_DEVICE="''${WARMCAM_OUTPUT:-/dev/video10}"
  TEMPERATURE="''${WARMCAM_TEMP:-2600}"  # Lower = warmer (daylight ~6500K, tungsten ~3200K)
  MIX="''${WARMCAM_MIX:-0.6}"            # 0-1, how much to apply the temperature shift
  RESOLUTION="''${WARMCAM_RES:-1920x1080}"
  FRAMERATE="''${WARMCAM_FPS:-60}"

  usage() {
    cat <<EOF
  warmcam - Virtual camera with color temperature correction

  Usage: warmcam [OPTIONS] [start|stop|status]

  Commands:
    start   Start the virtual camera pipeline (default)
    stop    Stop any running warmcam instance
    status  Show current status

  Options:
    -i, --input DEVICE    Input camera device (default: $INPUT_DEVICE)
    -o, --output DEVICE   Output virtual device (default: $OUTPUT_DEVICE)
    -t, --temp KELVIN     Color temperature (default: $TEMPERATURE)
                          Lower = warmer: 3200 (tungsten), 4500 (warm), 6500 (daylight)
    -m, --mix FLOAT       Mix amount 0.0-1.0 (default: $MIX)
    -r, --res WxH         Resolution (default: $RESOLUTION)
    -f, --fps N           Framerate (default: $FRAMERATE)
    -h, --help            Show this help

  Environment variables:
    WARMCAM_INPUT, WARMCAM_OUTPUT, WARMCAM_TEMP, WARMCAM_MIX, WARMCAM_RES, WARMCAM_FPS

  Examples:
    warmcam                     # Start with defaults (warm 2600k)
    warmcam -t 3500 -m 0.8      # Very warm, strong effect
    warmcam -t 5500 -m 0.3      # Slight warmth
    warmcam stop                # Stop running instance
  EOF
  }

  # Parse arguments
  CMD="start"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--input) INPUT_DEVICE="$2"; shift 2 ;;
      -o|--output) OUTPUT_DEVICE="$2"; shift 2 ;;
      -t|--temp) TEMPERATURE="$2"; shift 2 ;;
      -m|--mix) MIX="$2"; shift 2 ;;
      -r|--res) RESOLUTION="$2"; shift 2 ;;
      -f|--fps) FRAMERATE="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      start|stop|status) CMD="$1"; shift ;;
      *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  is_running() {
    if [[ -f "$PIDFILE" ]]; then
      local pid
      pid=$(${coreutils}/bin/cat "$PIDFILE")
      if kill -0 "$pid" 2>/dev/null; then
        return 0
      else
        # Stale PID file
        ${coreutils}/bin/rm -f "$PIDFILE"
      fi
    fi
    return 1
  }

  cmd_status() {
    if is_running; then
      local pid
      pid=$(${coreutils}/bin/cat "$PIDFILE")
      echo "warmcam is running (PID: $pid)"
      return 0
    else
      echo "warmcam is not running"
      return 1
    fi
  }

  cmd_stop() {
    if is_running; then
      local pid
      pid=$(${coreutils}/bin/cat "$PIDFILE")
      if kill "$pid" 2>/dev/null; then
        ${coreutils}/bin/rm -f "$PIDFILE"
        echo "Stopped warmcam (PID: $pid)"
      else
        ${coreutils}/bin/rm -f "$PIDFILE"
        echo "warmcam process already dead, cleaned up PID file"
      fi
    else
      echo "warmcam was not running"
    fi
  }

  cmd_start() {
    # Check if already running
    if is_running; then
      local pid
      pid=$(${coreutils}/bin/cat "$PIDFILE")
      echo "warmcam is already running (PID: $pid). Use 'warmcam stop' first."
      exit 1
    fi

    # Check input device
    if [[ ! -e "$INPUT_DEVICE" ]]; then
      echo "Error: Input device $INPUT_DEVICE does not exist"
      exit 1
    fi

    # Check output device (v4l2loopback)
    if [[ ! -e "$OUTPUT_DEVICE" ]]; then
      echo "Error: Output device $OUTPUT_DEVICE does not exist"
      echo "Make sure v4l2loopback module is loaded with: modprobe v4l2loopback"
      exit 1
    fi

    # Parse resolution
    WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
    HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)

    echo "Starting warmcam..."
    echo "  Input:       $INPUT_DEVICE"
    echo "  Output:      $OUTPUT_DEVICE"
    echo "  Temperature: ''${TEMPERATURE}K (mix: $MIX)"
    echo "  Resolution:  ''${WIDTH}x''${HEIGHT} @ ''${FRAMERATE}fps"
    echo ""
    echo "Use this virtual camera in your apps: $OUTPUT_DEVICE"
    echo ""

    # Note: colortemperature filter runs on CPU (no VAAPI support), but overhead is minimal
    ${ffmpeg}/bin/ffmpeg -hide_banner -loglevel warning \
      -f v4l2 -input_format yuyv422 -video_size "''${WIDTH}x''${HEIGHT}" -framerate "$FRAMERATE" \
      -i "$INPUT_DEVICE" \
      -vf "colortemperature=temperature=''${TEMPERATURE}:mix=''${MIX}" \
      -f v4l2 -pix_fmt yuyv422 \
      "$OUTPUT_DEVICE" &

    FFPID=$!
    echo "$FFPID" > "$PIDFILE"
    sleep 1

    # Check if ffmpeg started successfully
    if kill -0 "$FFPID" 2>/dev/null; then
      echo "warmcam started with PID $FFPID"
      echo "Tip: Run 'warmcam status' to check, 'warmcam stop' to stop"
    else
      ${coreutils}/bin/rm -f "$PIDFILE"
      echo "Error: ffmpeg failed to start. Check device permissions and formats."
      echo "Try running manually to see errors:"
      echo "  ffmpeg -f v4l2 -i $INPUT_DEVICE -vf 'colortemperature=temperature=$TEMPERATURE:mix=$MIX' -f v4l2 $OUTPUT_DEVICE"
      exit 1
    fi
  }

  case "$CMD" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    status) cmd_status ;;
  esac
''
