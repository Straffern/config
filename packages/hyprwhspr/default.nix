{ lib, python3Packages, fetchFromGitHub, makeWrapper, ydotool, bash, jq
, pulseaudio, pywhispercpp ? null }:

python3Packages.buildPythonApplication rec {
  pname = "hyprwhspr";
  version = "main"; # or a specific hash/tag

  src = fetchFromGitHub {
    owner = "goodroot";
    repo = "hyprwhspr";
    rev = "main";
    hash = "sha256-44WfFllAo0cVAOFGgJNwsgVyTUXz+arw2pumiU43Pf8=";
  };

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ pywhispercpp ] ++ (with python3Packages; [
    sounddevice
    numpy
    scipy
    evdev
    pyperclip
    requests
    websocket-client
    psutil
    pyudev
    pulsectl
    dbus-python
    rich
    pygobject3
  ]);

  # We need to install the library files and the bin script
  # hyprwhspr doesn't have a standard setup.py
  # It seems designed to be run from /usr/lib/hyprwhspr/bin/hyprwhspr

  format = "other";

  installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib/hyprwhspr
        cp -r * $out/lib/hyprwhspr/

        # Create the main executable
        # The entry point is bin/hyprwhspr which is a shell script wrapper usually
        # or we can just point to lib/cli.py or lib/main.py

        makeWrapper ${python3Packages.python}/bin/python $out/bin/hyprwhspr \
          --prefix PYTHONPATH : "$PYTHONPATH:$out/lib/hyprwhspr/lib" \
          --prefix PYTHONPATH : "${
            python3Packages.makePythonPath propagatedBuildInputs
          }" \
          --set HYPRWHSPR_ROOT "$out/lib/hyprwhspr" \
          --add-flags "$out/lib/hyprwhspr/lib/cli.py"

        # Add another one for the daemon
        makeWrapper ${python3Packages.python}/bin/python $out/bin/hyprwhspr-daemon \
          --prefix PYTHONPATH : "$PYTHONPATH:$out/lib/hyprwhspr/lib" \
          --prefix PYTHONPATH : "${
            python3Packages.makePythonPath propagatedBuildInputs
          }" \
          --set HYPRWHSPR_ROOT "$out/lib/hyprwhspr" \
          --add-flags "$out/lib/hyprwhspr/lib/main.py"

        # Fix shebang in tray script for NixOS
        substituteInPlace $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
          --replace-fail '#!/bin/bash' '#!${bash}/bin/bash'
        chmod +x $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh

        # Inject BT-aware mic detection functions after model_exists function
        # This allows the tray script to recognize when hyprwhspr-bt-switcher will provide a mic
        substituteInPlace $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
          --replace-fail '# Microphone detection functions (clean, fast, reliable)' \
    '# Check if hyprwhspr-bt-switcher service is running
    is_bt_switcher_running() {
        systemctl --user is-active --quiet hyprwhspr-bt-switcher.service
    }

    # Check if a Bluetooth headset with mic capability (mSBC/headset-head-unit profile) is available
    # This checks if the profile EXISTS, not if it is currently active
    bt_headset_mic_available() {
        # Find connected Bluetooth cards with headset-head-unit profile available
        local card_info
        card_info=$(pactl --format=json list cards 2>/dev/null | jq -r '"'"'
            .[] |
            select(.name | startswith("bluez_card")) |
            select(.properties["api.bluez5.connection"] == "connected") |
            select(.profiles | keys | any(startswith("headset-head-unit"))) |
            .name
        '"'"' 2>/dev/null)
        
        [[ -n "$card_info" ]]
    }

    # Check if BT switcher will provide mic when needed
    # Returns true if bt-switcher is running AND a BT headset with mic capability is connected
    bt_mic_will_be_available() {
        is_bt_switcher_running && bt_headset_mic_available
    }

    # Microphone detection functions (clean, fast, reliable)'

        # Modify mic detection to skip error when BT switcher will provide mic
        substituteInPlace $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
          --replace-fail \
    '    if [[ "$in_recovery_grace" == "false" ]]; then
            if ! mic_present || ! mic_accessible; then
                echo "error:mic_unavailable"; return
            fi
        fi' \
    '    if [[ "$in_recovery_grace" == "false" ]]; then
            # If BT switcher is running and BT headset with mic is available,
            # trust that mic will be provided when recording starts
            if bt_mic_will_be_available; then
                : # Skip mic check - BT switcher will handle profile switching
            elif ! mic_present || ! mic_accessible; then
                echo "error:mic_unavailable"; return
            fi
        fi'

    # Wrap tray script to ensure jq and pactl are available
    mv $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
       $out/lib/hyprwhspr/config/hyprland/.hyprwhspr-tray-unwrapped.sh
    makeWrapper $out/lib/hyprwhspr/config/hyprland/.hyprwhspr-tray-unwrapped.sh \
      $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
      --prefix PATH : "${lib.makeBinPath [ jq pulseaudio ]}"
  '';

  meta = with lib; {
    description = "Native speech-to-text for Hyprland";
    homepage = "https://github.com/goodroot/hyprwhspr";
    license = licenses.mit;
    maintainers = [ ];
  };
}
