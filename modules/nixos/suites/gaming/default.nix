{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace}; let
  cfg = config.${namespace}.suites.gaming;

  # Gamescope session wrapper — replaces the barebones nixpkgs script.
  #
  # nixpkgs' steam-gamescope runs `gamescope ... -- steam ...` with no
  # session management: no DISPLAY propagation to dbus-activated services,
  # no graphical-session.target, no XDG_CURRENT_DESKTOP. This causes
  # xdg-desktop-portal-gtk to crash ("cannot open display") which blocks
  # Steam's bootstrapping and kills the session.
  #
  # This wrapper:
  #   1. Logs all output for debuggability
  #   2. Sets session identity vars and propagates them to dbus/systemd
  #   3. Polls for XWayland sockets and propagates DISPLAY
  #   4. Starts graphical-session.target so dependent services work
  #   5. Cleans up on exit
  #
  # Uses the security-wrapper gamescope binary for CAP_SYS_NICE.
  gamescopeCmd = "${config.security.wrapperDir}/gamescope";

  steam-gamescope = pkgs.writeShellScript "steam-gamescope" ''
    set -uo pipefail

    LOG="/tmp/gamescope-session.log"
    echo "=== gamescope session $(date --iso-8601=seconds) ===" >> "$LOG"
    exec > >(tee -a "$LOG") 2>&1

    export XDG_CURRENT_DESKTOP=gamescope
    export XDG_SESSION_DESKTOP=gamescope

    # Pre-compositor env — lets dbus services know the desktop identity.
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP

    # Snapshot existing X sockets before gamescope creates new ones.
    BEFORE_SOCKETS=$(ls /tmp/.X11-unix/ 2>/dev/null || true)

    # Launch gamescope in background so we can detect the XWayland socket.
    ${gamescopeCmd} --steam \
      --xwayland-count 2 \
      --adaptive-sync \
      -w 1920 -h 1280 \
      -- steam -tenfoot -pipewire-dmabuf &
    GAMESCOPE_PID=$!
    echo "gamescope started (pid $GAMESCOPE_PID)"

    # Poll for gamescope's XWayland socket (up to 30s).
    DISPLAY_FOUND=""
    for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
      # Check gamescope is still alive.
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

    # Block until gamescope exits.
    wait $GAMESCOPE_PID
    EXIT_CODE=$?
    echo "gamescope exited ($EXIT_CODE)"

    # Teardown
    ${pkgs.systemd}/bin/systemctl --user stop --no-block gamescope-session.target 2>/dev/null || true
    echo "=== session ended $(date --iso-8601=seconds) ==="
  '';

  # Session .desktop file for the greeter.
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
  options.${namespace}.suites.gaming = with types; {
    enable = mkBoolOpt false "Enable the gaming suite";
  };

  config = mkIf cfg.enable {
    hardware = {
      # xpadneo.enable = true;
      # xone.enable = true;

      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          mesa
          libva
          libvdpau-va-gl
          vulkan-loader
          vulkan-validation-layers
          mesa.opencl # Enables Rusticl (OpenCL) support
          rocmPackages.clr.icd
        ];
      };
    };

    services.ratbagd.enable = true;

    programs = {
      gamemode.enable = true;
      gamescope = {
        enable = true;
        capSysNice = true; # Needed for DRM session scheduling + setuid bwrap
      };
      steam = {
        enable = true;
        package =
          pkgs.steam.override {extraPkgs = p: with p; [mangohud gamemode];};
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;

        # Keep gamescopeSession enabled — this sets up the setuid bwrap
        # wrapper and the Steam FHS buildenv override that capSysNice needs.
        # We override the session .desktop below with our proper wrapper.
        gamescopeSession.enable = true;

        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };

    # Replace the barebones nixpkgs session file with our wrapper.
    services.displayManager.sessionPackages = mkForce [
      config.programs.niri.package # preserve niri session
      gamescopeSessionFile
    ];

    # Shim target: starting this pulls in graphical-session.target via BindsTo,
    # which is the only sanctioned way (graphical-session.target refuses manual start).
    systemd.user.targets.gamescope-session = {
      description = "Gamescope Steam session";
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target"];
      after = ["graphical-session-pre.target"];
    };

    services.xserver.videoDrivers = ["amdgpu"];
    environment.variables = {
      RUSTICL_ENABLE = "radeonsi";
      ROC_ENABLE_PRE_VEGA = "1";
    };

    environment.systemPackages = with pkgs; [
      winetricks
      wineWowPackages.waylandFull
      adwsteamgtk
      mesa-demos
      vulkan-tools
      clinfo
      ffmpeg
    ];
  };
}
