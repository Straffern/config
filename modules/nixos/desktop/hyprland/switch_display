#!/usr/bin/env bash

# Function to send notification
notify() {
  notify-send "Display Configuration" "$1" -i video-display
}

# Get list of connected monitors
monitors_output=$(hyprctl monitors)

external_monitor=$(echo "$monitors_output" | grep -E "^Monitor.*(DP|[HD]).*-[A0-9]*-?[0-9]" | head -n1 | awk '{print $2}')

if [ -n "$external_monitor" ]; then
  # Get first mode that matches 59.xx or 60Hz at minimum 1920x1080
  # Get available modes for the external monitor
  mode=$(echo "$monitors_output" |
    awk "/Monitor $external_monitor/{f=1} f&&/availableModes:/{split(\$0,a,\": \"); print a[2]; f=0}" |
    grep -o '[0-9]\+x[0-9]\+@[0-9]\+\.[0-9]\+Hz' |
    grep -E "1920x1080@|2560x1440@|3840x2160@" |
    grep -E "@59\.[0-9]+Hz|@60\.00Hz" | head -n1 |
    sed 's/Hz//')

  if [ -n "$mode" ]; then
    hyprctl keyword monitor "$external_monitor,$mode,auto,1"
    hyprctl keyword monitor "eDP-1,disable"
    notify "Switched to external display ($external_monitor) at $mode"
  else
    # Fallback to preferred if no suitable mode found
    hyprctl keyword monitor "$external_monitor,preferred,auto,1"
    hyprctl keyword monitor "eDP-1,disable"
    notify "Switched to external display ($external_monitor) at preferred mode"
  fi
else
  # If no external monitor, use eDP-1
  hyprctl keyword monitor "eDP-1,preferred,auto,1"
  notify "Switched to laptop display"
fi
