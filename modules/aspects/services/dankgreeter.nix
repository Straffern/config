{
  den,
  inputs,
  ...
}: {
  den.aspects.services.dankgreeter = {
    vmSmoke = [
      {
        name = "dank-greeter";
        description = "Dank Greeter remains alive";
        phase = "greeter";
        module = {
          systemd.tmpfiles.rules = [
            "d /var/lib/dms-greeter 0750 greeter greeter -"
            "f /var/lib/dms-greeter/wallpaper 0644 greeter greeter - wallpaper"
            "f /var/lib/dms-greeter/session.json 0644 greeter greeter - {\\\"wallpaperPath\\\":\\\"/var/lib/dms-greeter/wallpaper\\\"}"
            "f /var/lib/dms-greeter/custom-theme.json 0644 greeter greeter - {}"
            "f /var/lib/dms-greeter/settings.json 0644 greeter greeter - {\\\"customThemeFile\\\":\\\"/var/lib/dms-greeter/custom-theme.json\\\"}"
          ];
        };
        script = ''
          machine.wait_for_unit("greetd.service")
          machine.wait_until_succeeds("pgrep -x dms-greeter")
          machine.sleep(5)
          machine.succeed("systemctl is-active --quiet greetd.service")
          machine.succeed("pgrep -x dms-greeter")
        '';
      }
    ];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cacheDir = "/var/lib/dms-greeter";
      cfg = config.programs.dms-greeter;
      jq = lib.getExe pkgs.jq;
    in {
      imports = [inputs.dank-greeter.nixosModules.default];
      programs.dms-greeter = {
        enable = true;
        quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      users.users.greeter.home = "/var/lib/dms-greeter";
      services.fprintd.enable = true;
      security.pam.services.login.fprintAuth = false;
      security.pam.services = {
        greetd = {
          fprintAuth = true;
          rules.auth.fprintd.settings = {
            "max-tries" = "2";
            timeout = "10";
          };
        };
        dms-greeter = {
          fprintAuth = true;
          rules.auth.fprintd.settings = {
            "max-tries" = "2";
            timeout = "10";
          };
        };
      };
      environment.systemPackages = [pkgs.fprintd];
      systemd.services.greetd = {
        # Upstream localizes wallpaper paths into cacheDir. On the next boot the
        # cached session already points there, so cp otherwise rejects copying a
        # file onto itself and prevents greetd from starting.
        preStart = lib.mkForce ''
          cd ${cacheDir}
          ${lib.concatMapStringsSep "\n" (file: ''
              if [ -f ${lib.escapeShellArg file} ]; then
                cp ${lib.escapeShellArg file} .
              fi
            '')
            cfg.configFiles}

          if [ -f session.json ]; then
            copy_wallpaper() {
              local path
              path=$(${jq} -r ".$1 // empty" session.json)
              if [ -f "$path" ]; then
                if [ "$(readlink -f "$path")" != "$(readlink -f "$2")" ]; then
                  cp "$path" "$2"
                fi
                ${jq} ".$1 = \"${cacheDir}/$2\"" session.json > session.tmp
                mv session.tmp session.json
              fi
            }

            copy_monitor_wallpapers() {
              ${jq} -r ".$1 // {} | to_entries[] | .key + \":\" + .value" session.json 2>/dev/null | while IFS=: read -r monitor path; do
                local dest="$2-$(echo "$monitor" | tr -c '[:alnum:]' '-')"
                if [ -f "$path" ]; then
                  if [ "$(readlink -f "$path")" != "$(readlink -f "$dest")" ]; then
                    cp "$path" "$dest"
                  fi
                  ${jq} --arg m "$monitor" --arg p "${cacheDir}/$dest" ".$1[\$m] = \$p" session.json > session.tmp
                  mv session.tmp session.json
                fi
              done
            }

            copy_wallpaper "wallpaperPath" "wallpaper"
            copy_wallpaper "wallpaperPathLight" "wallpaper-light"
            copy_wallpaper "wallpaperPathDark" "wallpaper-dark"
            copy_monitor_wallpapers "monitorWallpapers" "wallpaper-monitor"
            copy_monitor_wallpapers "monitorWallpapersLight" "wallpaper-monitor-light"
            copy_monitor_wallpapers "monitorWallpapersDark" "wallpaper-monitor-dark"
          fi

          if [ -f settings.json ]; then
            theme_file="$(${jq} -r '.customThemeFile // empty' settings.json)"
            if [ -f "$theme_file" ] && [ -r "$theme_file" ]; then
              if [ "$(readlink -f "$theme_file")" != "$(readlink -f custom-theme.json)" ]; then
                cp "$theme_file" custom-theme.json
              fi
              mv settings.json settings.orig.json
              ${jq} '.customThemeFile = "${cacheDir}/custom-theme.json"' settings.orig.json > settings.json
            fi
          fi

          mv dms-colors.json colors.json || :
          chown greeter: * || :
        '';
        serviceConfig = {
          Type = "idle";
          StandardInput = "tty";
          StandardOutput = "tty";
          StandardError = "journal";
          TTYReset = true;
          TTYVHangup = true;
          TTYVTDisallocate = true;
        };
      };
      systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
      systemd.user.extraConfig = "DefaultTimeoutStopSec=10s\n";
    };
  };
}
