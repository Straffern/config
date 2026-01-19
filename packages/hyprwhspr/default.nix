{
  lib,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  ydotool,
  bash,
  jq,
  pulseaudio,
  pywhispercpp ? null,
}:
python3Packages.buildPythonApplication rec {
  pname = "hyprwhspr";
  version = "2026-01-09";

  src = fetchFromGitHub {
    owner = "goodroot";
    repo = "hyprwhspr";
    rev = "164fff26a3dfb9ab9ac2ac20bb64817af15fe53b";
    hash = "sha256-ZvRebZR/c9O62028JqoyyQn1TlAUv1ujjwZboY6C2NI=";
  };

  nativeBuildInputs = [makeWrapper];

  propagatedBuildInputs =
    [pywhispercpp ydotool]
    ++ (with python3Packages; [
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

        # Patch ydotool service check: upstream uses user-level ydotool.service,
        # but NixOS runs ydotoold as a system service (ydotoold.service).
        # Fix the is_ydotoold_running() function to check the correct service.
        substituteInPlace $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
          --replace-fail 'systemctl --user is-active --quiet ydotool.service' \
                         'systemctl is-active --quiet ydotoold.service'

        chmod +x $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh

    # Wrap tray script to ensure jq and pactl are available
    mv $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
       $out/lib/hyprwhspr/config/hyprland/.hyprwhspr-tray-unwrapped.sh
    makeWrapper $out/lib/hyprwhspr/config/hyprland/.hyprwhspr-tray-unwrapped.sh \
      $out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh \
      --prefix PATH : "${lib.makeBinPath [jq pulseaudio]}"
  '';

  meta = with lib; {
    description = "Native speech-to-text for Hyprland";
    homepage = "https://github.com/goodroot/hyprwhspr";
    license = licenses.mit;
    maintainers = [];
  };
}
