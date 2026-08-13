{den, ...}: {
  den.aspects.gaming.niri-session = {
    includes = [
      den.aspects.profiles.gaming
      den.aspects.gaming.amd-graphics
      den.aspects.desktop.niri
    ];

    nixos = {
      config,
      pkgs,
      ...
    }: let
      # nixpkgs' steam-gamescope session does not propagate its XWayland
      # display or graphical-session target to user services. Keep this
      # integration at the explicit Gaming + Niri selection boundary instead
      # of making reusable gaming.core depend on Niri.
      gamescopeCmd = "${config.security.wrapperDir}/gamescope";

      steam-gamescope = pkgs.writeShellScript "steam-gamescope" ''
        set -uo pipefail

        LOG="/tmp/gamescope-session.log"
        echo "=== gamescope session $(date --iso-8601=seconds) ===" >> "$LOG"
        exec > >(tee -a "$LOG") 2>&1

        export XDG_CURRENT_DESKTOP=gamescope
        export XDG_SESSION_DESKTOP=gamescope

        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
          XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP

        BEFORE_SOCKETS=$(ls /tmp/.X11-unix/ 2>/dev/null || true)

        ${gamescopeCmd} --steam \
          --xwayland-count 2 \
          --adaptive-sync \
          -w 1920 -h 1280 \
          -- steam -tenfoot -pipewire-dmabuf &
        GAMESCOPE_PID=$!
        echo "gamescope started (pid $GAMESCOPE_PID)"

        DISPLAY_FOUND=""
        for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
          if ! kill -0 $GAMESCOPE_PID 2>/dev/null; then
            echo "ERROR: gamescope exited before display was ready"
            wait $GAMESCOPE_PID
            exit $?
          fi

          for i in $(${pkgs.coreutils}/bin/seq 0 15); do
            case " $BEFORE_SOCKETS " in
              *" X$i "*) continue ;;
            esac
            if [ -S "/tmp/.X11-unix/X$i" ]; then
              DISPLAY_FOUND=":$i"
              break 2
            fi
          done
          sleep 0.5
        done

        if [ -n "$DISPLAY_FOUND" ]; then
          export DISPLAY="$DISPLAY_FOUND"
          echo "found DISPLAY=$DISPLAY"
          ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY
          ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY
          ${pkgs.systemd}/bin/systemctl --user start --no-block gamescope-session.target
          echo "session environment propagated"
        else
          echo "WARNING: could not discover DISPLAY after 30s"
        fi

        wait $GAMESCOPE_PID
        EXIT_CODE=$?
        echo "gamescope exited ($EXIT_CODE)"

        ${pkgs.systemd}/bin/systemctl --user stop --no-block gamescope-session.target 2>/dev/null || true
        echo "=== session ended $(date --iso-8601=seconds) ==="
      '';

      gamescopeSessionFile =
        (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
          [Desktop Entry]
          Name=Steam
          Comment=Steam Big Picture in Gamescope compositor
          Exec=${steam-gamescope}
          Type=Application
        '').overrideAttrs
        (_: {
          passthru.providedSessions = ["steam"];
        });
    in {
      # The Niri module and this session contribute independently. Native list
      # merging preserves both, as well as any future display-manager sessions.
      services.displayManager.sessionPackages = [gamescopeSessionFile];

      systemd.user.targets.gamescope-session = {
        description = "Gamescope Steam session";
        bindsTo = ["graphical-session.target"];
        wants = ["graphical-session-pre.target"];
        after = ["graphical-session-pre.target"];
      };
    };
  };
}
