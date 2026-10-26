#!/usr/bin/env bash
set -u

host="${NR7302_HOST:-root@192.168.1.1}"
interval="${NR7302_INTERVAL:-2}"
once=false
raw=false
neighbors=false

usage() {
  cat <<'USAGE'
Usage: nr7302-monitor [options]

Options:
  -H, --host HOST       SSH destination (default: root@192.168.1.1)
  -i, --interval SEC    Refresh interval (default: 2)
  -1, --once            Print one sample and exit
  -n, --neighbors       Include neighboring LTE cells
  -r, --raw             Print raw modem responses once
  -h, --help            Show this help

Environment:
  NR7302_HOST           Default SSH destination
  NR7302_INTERVAL       Default refresh interval
USAGE
}

while (($#)); do
  case "$1" in
    -H|--host)
      (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
      host=$2
      shift 2
      ;;
    -i|--interval)
      (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
      interval=$2
      shift 2
      ;;
    -1|--once)
      once=true
      shift
      ;;
    -n|--neighbors)
      neighbors=true
      shift
      ;;
    -r|--raw)
      raw=true
      once=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ $interval =~ ^[0-9]+([.][0-9]+)?$ ]] || {
  printf 'Invalid interval: %s\n' "$interval" >&2
  exit 2
}

remote_commands=$(cat <<'REMOTE'
printf '%s\n' __QENG__
atcmd 'AT+QENG="servingcell"' 2>/dev/null || :
printf '%s\n' __QCAINFO__
atcmd 'AT+QCAINFO' 2>/dev/null || :
printf '%s\n' __QNWINFO__
atcmd 'AT+QNWINFO' 2>/dev/null || :
REMOTE
)

if $neighbors; then
  remote_commands+=$'\nprintf \'%s\\n\' __NEIGHBORS__\natcmd \'AT+QENG="neighbourcell"\' 2>/dev/null || :\n'
fi

collect() {
  ssh \
    -o ConnectTimeout=5 \
    -o ControlMaster=auto \
    -o ControlPath="${XDG_RUNTIME_DIR:-/tmp}/nr7302-%C" \
    -o ControlPersist=60 \
    "$host" "$remote_commands" 2>&1
}

sample() {
  local attempt=0 output

  while ((attempt < 3)); do
    ((attempt += 1))
    output=$(collect) || true
    if [[ $output == *'+QENG:'* || $output == *'+QCAINFO:'* ]]; then
      printf '%s\n' "$output"
      return
    fi
    sleep 1
  done

  printf '%s\n' "$output"
}

render() {
  local color=$1
  gawk -F, -v color="$color" -v host="$host" '
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}
function val(s) {
  gsub(/"/, "", s)
  return trim(s)
}
function first(s) {
  sub(/^[^"]*"/, "", s)
  return val(s)
}
function lte_bw(x) {
  return x == 0 ? "1.4" : x == 1 ? "3" : x == 2 ? "5" :
         x == 3 ? "10" : x == 4 ? "15" : x == 5 ? "20" : "?"
}
function nr_bw(x) {
  return x == 0 ? "5" : x == 1 ? "10" : x == 2 ? "15" :
         x == 3 ? "20" : x == 4 ? "25" : x == 5 ? "30" :
         x == 6 ? "40" : x == 7 ? "50" : x == 8 ? "60" :
         x == 9 ? "70" : x == 10 ? "80" : x == 11 ? "90" :
         x == 12 ? "100" : x == 13 ? "200" : x == 14 ? "400" : "?"
}
function ca_lte_bw(x) {
  return x == 6 ? "1.4" : x == 15 ? "3" : x == 25 ? "5" :
         x == 50 ? "10" : x == 75 ? "15" : x == 100 ? "20" : "?"
}
function metric(v, kind, width, n, code, padded) {
  padded = sprintf("%-*s", width, v)
  if (!color || v == "-" || v == "") return padded
  n = v + 0
  if (kind == "rsrp")
    code = n >= -90 ? 32 : n >= -100 ? 36 : n >= -110 ? 33 : 31
  else if (kind == "rsrq")
    code = n >= -10 ? 32 : n >= -13 ? 36 : n >= -16 ? 33 : 31
  else
    code = n >= 20 ? 32 : n >= 13 ? 36 : n >= 5 ? 33 : 31
  return sprintf("\033[%dm%s\033[0m", code, padded)
}
function serving_row(rat, band, pci, channel, bw, rsrp, rsrq, sinr, rssi, prefix) {
  prefix = sprintf("%-5s %-5s %-5s %-9s %-7s ", rat, band, pci, channel, bw)
  serving[++serving_n] = sprintf("%s%s %s %s %-7s", prefix,
    metric(rsrp, "rsrp", 15), metric(rsrq, "rsrq", 15),
    metric(sinr, "sinr", 15), rssi)
}
function ca_row(role, band, channel, bw, pci, rsrp, rsrq, rssi, sinr, prefix) {
  prefix = sprintf("%-5s %-14s %-9s %-7s %-5s ", role, band, channel, bw, pci)
  ca[++ca_n] = sprintf("%s%s %s %s %-7s", prefix,
    metric(rsrp, "rsrp", 15), metric(rsrq, "rsrq", 15),
    metric(sinr, "sinr", 15), rssi)
}
/^__QENG__$/ { section = "qeng"; next }
/^__QCAINFO__$/ { section = "ca"; next }
/^__QNWINFO__$/ { section = "network"; next }
/^__NEIGHBORS__$/ { section = "neighbors"; next }
section == "qeng" && /^\+QENG: "servingcell".*"NR5G-SA"/ {
  state = val($2)
  serving_row("NR", val($11), val($8), val($10), nr_bw(val($12)),
    val($13), val($14), val($15), "-")
  next
}
section == "qeng" && /^\+QENG: "servingcell"/ { state = val($2); next }
section == "qeng" && /^\+QENG: "LTE"/ {
  serving_row("LTE", val($8), val($6), val($7), lte_bw(val($10)),
    val($12), val($13), val($15), val($14))
  next
}
section == "qeng" && /^\+QENG: "NR5G-NSA"/ {
  serving_row("NR", val($9), val($4), val($8), nr_bw(val($10)),
    val($5), val($7), val($6), "-")
  next
}
section == "ca" && /^\+QCAINFO:/ {
  count = split($0, a, ",")
  role = first(a[1]); band = val(a[4])
  if (band ~ /^LTE/) {
    ca_row(role, band, val(a[2]), ca_lte_bw(val(a[3])), val(a[6]),
      val(a[7]), val(a[8]), val(a[9]), val(a[10]))
  } else if (count >= 12) {
    ca_row(role, band, val(a[2]), nr_bw(val(a[3])), val(a[6]),
      val(a[10]), val(a[11]), "-", "-")
  } else {
    ca_row(role, band, val(a[2]), nr_bw(val(a[3])), val(a[5]),
      val(a[6]), val(a[7]), "-", "-")
  }
  next
}
section == "network" && /^\+QNWINFO:/ {
  network[++network_n] = sprintf("%s  PLMN %s  %s  channel %s",
    first($1), val($2), val($3), val($4))
  next
}
section == "neighbors" && /^\+QENG: "neighbourcell/ {
  neighbor[++neighbor_n] = $0
  next
}
/Permission denied|Connection timed out|Could not resolve|No route to host|Connection refused|Host key verification failed/ {
  error = $0
}
END {
  if (error != "") {
    print "nr7302-monitor: " error > "/dev/stderr"
    exit 1
  }
  if (serving_n == 0 && ca_n == 0) {
    print "nr7302-monitor: the modem returned no radio data" > "/dev/stderr"
    exit 1
  }
  printf "NR7302 radio monitor  %s  %s\n", host, strftime("%Y-%m-%d %H:%M:%S")
  if (state != "") printf "Modem state: %s\n", state
  for (i = 1; i <= network_n; i++) print network[i]

  print ""
  print "SERVING CELLS"
  printf "%-5s %-5s %-5s %-9s %-7s %-15s %-15s %-15s %-7s\n",
    "RAT", "BAND", "PCI", "CHANNEL", "BW MHz", "RSRP dBm", "RSRQ dB", "SINR dB", "RSSI"
  for (i = 1; i <= serving_n; i++) print serving[i]

  print ""
  print "CARRIER AGGREGATION"
  printf "%-5s %-14s %-9s %-7s %-5s %-15s %-15s %-15s %-7s\n",
    "ROLE", "BAND", "CHANNEL", "BW MHz", "PCI", "RSRP dBm", "RSRQ dB", "SINR dB", "RSSI"
  for (i = 1; i <= ca_n; i++) print ca[i]

  if (neighbor_n) {
    print ""
    print "NEIGHBOR CELLS (raw)"
    for (i = 1; i <= neighbor_n; i++) print neighbor[i]
  }

  print ""
  print "Priority: stable cell -> SINR -> RSRQ -> RSRP. Press Ctrl-C to exit."
}'
}

if $raw; then
  sample
  exit
fi

if $once || [[ ! -t 1 ]]; then
  sample | render 0
  exit
fi

cleanup() {
  printf '\033[?25h\033[0m\n'
}

trap cleanup EXIT
trap 'exit 130' INT TERM
printf '\033[?25l'
while true; do
  output=$(sample)
  printf '\033[H\033[2J'
  printf '%s\n' "$output" | render 1 || true
  sleep "$interval"
done
