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
