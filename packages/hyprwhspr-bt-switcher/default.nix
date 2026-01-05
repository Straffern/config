{ lib, writeShellApplication, pulseaudio, jq, inotify-tools }:

writeShellApplication {
  name = "hyprwhspr-bt-switcher";

  runtimeInputs = [ pulseaudio jq inotify-tools ];

  text = ''
    WATCH_FILE="$HOME/.config/hyprwhspr/recording_status"
    WATCH_DIR="$(dirname "$WATCH_FILE")"
    STATE_FILE="/tmp/hyprwhspr-bt-state.json"

    mkdir -p "$WATCH_DIR"

    echo "Bluetooth switcher started, watching $WATCH_DIR"

    switch_to_msbc() {
      # Find connected Bluetooth card
      CARD_INFO=$(pactl --format=json list cards | jq -r '.[] | select(.name | startswith("bluez_card")) | select(.properties["api.bluez5.connection"] == "connected") | {name: .name, profile: .active_profile, profiles: .profiles | keys}')
      
      if [[ -z "$CARD_INFO" ]]; then
        echo "No connected Bluetooth card found"
        return
      fi

      CARD_NAME=$(echo "$CARD_INFO" | jq -r '.name')
      PREV_PROFILE=$(echo "$CARD_INFO" | jq -r '.profile')
      
      # Save state
      echo "{\"name\": \"$CARD_NAME\", \"prev_profile\": \"$PREV_PROFILE\"}" > "$STATE_FILE"
      
      # Find mSBC profile
      TARGET_PROFILE=$(echo "$CARD_INFO" | jq -r '.profiles[]' | grep "headset-head-unit" | head -n 1)
      
      if [[ -n "$TARGET_PROFILE" ]]; then
        echo "Switching $CARD_NAME to $TARGET_PROFILE (prev: $PREV_PROFILE)"
        pactl set-card-profile "$CARD_NAME" "$TARGET_PROFILE"
        # Small delay for BT driver
        sleep 0.4
      else
        echo "mSBC profile not found for $CARD_NAME"
      fi
    }

    restore_profile() {
      if [[ -f "$STATE_FILE" ]]; then
        CARD_NAME=$(jq -r '.name' "$STATE_FILE")
        PREV_PROFILE=$(jq -r '.prev_profile' "$STATE_FILE")
        
        echo "Restoring $CARD_NAME to $PREV_PROFILE"
        pactl set-card-profile "$CARD_NAME" "$PREV_PROFILE"
        rm "$STATE_FILE"
      fi
    }

    # Initial state check
    if [[ -f "$WATCH_FILE" ]]; then
      switch_to_msbc
    fi

    # Watch for changes
    inotifywait -m -e create,delete "$WATCH_DIR" | while read -r _ event filename; do
      if [[ "$filename" == "recording_status" ]]; then
        if [[ "$event" == "CREATE" ]]; then
          switch_to_msbc
        elif [[ "$event" == "DELETE" ]]; then
          restore_profile
        fi
      fi
    done
  '';
}
