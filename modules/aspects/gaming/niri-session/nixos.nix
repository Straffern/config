{den, ...}: {
  den.aspects.gaming.niri-session = {
    includes = [
      den.aspects.profiles.gaming
      den.aspects.desktop.niri
    ];

    nixos = {
      config,
      pkgs,
      ...
    }: let
      # Gamescope keeps CAP_SYS_NICE for scheduling. The package patch clears
      # ambient capabilities only in forked children before they exec Steam.
      gamescopeCmd = "${config.security.wrapperDir}/gamescope";

      steam-gamescope = pkgs.writeShellScript "steam-gamescope" ''
        set -euo pipefail

        echo "=== gamescope session $(date --iso-8601=seconds) ==="

        export XDG_CURRENT_DESKTOP=gamescope
        export XDG_SESSION_DESKTOP=gamescope
        GAMESCOPE_PID=""

        cleanup() {
          status=$?
          trap - EXIT INT TERM HUP
          ${pkgs.systemd}/bin/systemctl --user stop gamescope-session.target graphical-session.target 2>/dev/null || true
          ${pkgs.systemd}/bin/systemctl --user unset-environment DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null || true
          if [ -n "$GAMESCOPE_PID" ] && kill -0 "$GAMESCOPE_PID" 2>/dev/null; then
            kill "$GAMESCOPE_PID" 2>/dev/null || true
            for _attempt in $(${pkgs.coreutils}/bin/seq 1 50); do
              kill -0 "$GAMESCOPE_PID" 2>/dev/null || break
              ${pkgs.coreutils}/bin/sleep 0.1
            done
            kill -KILL "$GAMESCOPE_PID" 2>/dev/null || true
            wait "$GAMESCOPE_PID" 2>/dev/null || true
          fi
          echo "=== session ended $(date --iso-8601=seconds) ($status) ==="
          exit "$status"
        }
        trap cleanup EXIT
        trap 'exit 129' HUP
        trap 'exit 130' INT
        trap 'exit 143' TERM

        ${gamescopeCmd} --steam \
          --xwayland-count 2 \
          --adaptive-sync \
          -- ${pkgs.bash}/bin/bash -c '
              ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
                DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP
              ${pkgs.systemd}/bin/systemctl --user start gamescope-session.target
              exec "$@"
            ' bash ${config.programs.steam.package}/bin/steam -tenfoot -pipewire-dmabuf &
        GAMESCOPE_PID=$!
        echo "gamescope started (pid $GAMESCOPE_PID)"

        set +e
        wait "$GAMESCOPE_PID"
        status=$?
        set -e
        GAMESCOPE_PID=""
        echo "gamescope exited ($status)"
        exit "$status"
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
        before = ["graphical-session.target"];
      };
    };
  };
}
