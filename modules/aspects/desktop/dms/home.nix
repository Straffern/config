{
  den,
  inputs,
  ...
}: {
  flake-file.inputs = {
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/master";
      inputs.nixpkgs.follows = "unstable";
    };
    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankcalendar = {
      url = "github:AvengeMedia/dankcalendar";
      inputs.nixpkgs.follows = "unstable";
    };
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "unstable";
    };
    quickshell = {
      url = "github:quickshell-mirror/quickshell/v0.3.1";
      inputs.nixpkgs.follows = "unstable";
    };
  };
  den.aspects.desktop.dms.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      concatStringsSep
      escapeShellArg
      mkForce
      mkIf
      mkMerge
      ;

    niriEnabled = config.programs.niri.enable or false;

    terminalCommand = "kitty";

    # --- DMS settings bootstrap (compositor-agnostic) ---

    dmsSettingsBootstrap = pkgs.writeText "dms-settings-bootstrap.json" (
      builtins.toJSON {
        blurEnabled = true;
        gtkThemingEnabled = true;
        runDmsMatugenTemplates = true;
        matugenTemplateNeovim = true;
        enableFprint = true;
        greeterEnableFprint = true;
        greeterRememberLastUser = true;
      }
    );

    bootstrapDmsSettings = let
      settingsPath = "${config.xdg.configHome}/DankMaterialShell/settings.json";
    in ''
      settings_path=${escapeShellArg settingsPath}
      settings_dir=$(${pkgs.coreutils}/bin/dirname "$settings_path")
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"

      if [ ! -e "$settings_path" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
          ${escapeShellArg "${dmsSettingsBootstrap}"} \
          "$settings_path"
      elif [ ! -w "$settings_path" ]; then
        echo "Skipping DMS settings bootstrap for read-only $settings_path" >&2
      elif ${pkgs.jq}/bin/jq -e . "$settings_path" >/dev/null; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.jq}/bin/jq '
          if type == "object" then
            (if has("blurEnabled") then . else . + { blurEnabled: true } end)
            | (if has("gtkThemingEnabled") then . else . + { gtkThemingEnabled: true } end)
            | (if has("runDmsMatugenTemplates") then . else . + { runDmsMatugenTemplates: true } end)
            | (if has("matugenTemplateNeovim") then . else . + { matugenTemplateNeovim: true } end)
            | (if has("enableFprint") then . else . + { enableFprint: true } end)
            | (if has("greeterEnableFprint") then . else . + { greeterEnableFprint: true } end)
            | (if has("greeterRememberLastUser") then . else . + { greeterRememberLastUser: true } end)
          else .
          end
        ' "$settings_path" > "$tmp"

        if ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$settings_path"; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$tmp" "$settings_path"
        else
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$tmp"
        fi
      else
        echo "Skipping DMS settings bootstrap due to invalid JSON in $settings_path" >&2
      fi
    '';

    restoreDmsBackup = path: ''
      target=${escapeShellArg path}
      backup="$target.pre-home-manager"
      if [ ! -e "$target" ] && [ ! -L "$target" ] && [ -f "$backup" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target")"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$backup" "$target"
      fi
    '';

    # --- Terminal theme stubs (compositor-agnostic) ---

    dmsTerminalFiles = {
      alacritty = pkgs.writeText "dms-alacritty-theme.toml" "";
      kittyTheme = pkgs.writeText "dms-kitty-theme.conf" "";
      kittyTabs = pkgs.writeText "dms-kitty-tabs.conf" "";
      foot = pkgs.writeText "dms-foot-colors.ini" "";
    };

    installMissingFile = source: target: ''
      if [ ! -e ${escapeShellArg target} ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
          ${escapeShellArg "${source}"} \
          ${escapeShellArg target}
      fi
    '';

    # --- Niri-specific: KDL config fragments from DMS source ---

    # Put DMS wallpaper layers into niri's overview backdrop. DMS requests blur via
    # ext-background-effect; keep blur opt-in in DMS, but use regular blur for
    # foreground shell layers. Background/bottom layers keep niri's efficient
    # default xray blur.
    dmsNiriLayerRules = ''
      layer-rule {
      	match namespace="^quickshell$"
      	place-within-backdrop true
      }

      layer-rule {
      	match namespace=r#"^dms:.*"# layer="top"
      	match namespace=r#"^dms:.*"# layer="overlay"
      	exclude namespace=r#"^dms:fade-to-(dpms|lock)$"#
      	exclude namespace=r#"^dms:desktop-widget-(preview|grid|helper)$"#

      	background-effect {
      		xray false
      	}
      }

      window-rule {
      	match app-id=r#"com.danklinux.dms$"#

      	background-effect {
      		xray false
      	}

      	popups {
      		background-effect {
      			xray false
      		}
      	}
      }
    '';

    dmsNiriFiles = {
      colors = pkgs.writeText "dms-niri-colors.kdl" (
        builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-colors.kdl"
      );
      layout = pkgs.writeText "dms-niri-layout.kdl" (
        builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-layout.kdl"
      );
      alttab = pkgs.writeText "dms-niri-alttab.kdl" (
        builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-alttab.kdl"
      );
      binds = pkgs.writeText "dms-niri-binds.kdl" (
        builtins.replaceStrings ["{{TERMINAL_COMMAND}}"] [terminalCommand] (
          builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-binds.kdl"
        )
      );
      outputs = pkgs.writeText "dms-niri-outputs.kdl" "";
      cursor = pkgs.writeText "dms-niri-cursor.kdl" "";
      windowrules = pkgs.writeText "dms-niri-windowrules.kdl" "";
      blur = pkgs.writeText "dms-niri-blur.kdl" dmsNiriLayerRules;

      wpblur = pkgs.writeText "dms-niri-wpblur.kdl" (
        builtins.readFile "${inputs.dms}/quickshell/Services/niri-wpblur.kdl"
      );
    };

    niriFilesToInclude = [
      "colors"
      "layout"
      "alttab"
      "binds"
      "outputs"
      "cursor"
      "windowrules"
      "blur"
      "wpblur"
    ];

    installMissingNiriFile = name: installMissingFile dmsNiriFiles.${name} "${config.xdg.configHome}/niri/dms/${name}.kdl";
    bootstrappedNiriFiles = builtins.filter (name: name != "blur") niriFilesToInclude;
  in {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
      inputs.danksearch.homeModules.dsearch
      inputs.dankcalendar.homeModules.default
    ];
    config = mkMerge [
      {
        programs.dank-material-shell = {
          enable = true;
          package = (inputs.dms.lib.mkDmsShell pkgs).overrideAttrs (old: {
            postInstall =
              old.postInstall
              + ''
                chmod -R u+w "$out/share/quickshell/dms"
                patch --fuzz=0 --no-backup-if-mismatch -d "$out/share/quickshell/dms" -p1 < ${./_assets/mic-volume.patch}
                patch --fuzz=0 --no-backup-if-mismatch -d "$out/share/quickshell/dms" -p1 < ${./_assets/matugen-custom-startup.patch}
              '';
          });
          systemd.enable = true;
          enableSystemMonitoring = true;
          enableDynamicTheming = true;
          enableClipboardPaste = true;
        };

        programs.kitty.extraConfig = lib.mkAfter ''
          include dank-tabs.conf
          include dank-theme.conf
        '';

        programs.dank-calendar = {
          enable = true;
          systemd.enable = true;
        };

        # HM owns dms.service, so mirror package unit semantics here and keep
        # local crash-loop hardening in same declarative unit. Reload targets
        # $MAINPID because wrapped Nix binaries run as `.dms-wrapped`, so
        # `pkill -x dms` misses them.
        systemd.user.services.dms = {
          Unit = {
            Description = mkForce "Dank Material Shell (DMS)";
            Requisite = [config.programs.dank-material-shell.systemd.target];
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
            OnFailure = ["dms-rescue.service"];
          };

          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
            RestartSec = "3s";
            SuccessExitStatus = [143];
            TimeoutStopSec = 10;
          };
        };
        systemd.user.services.dcal.Service.SuccessExitStatus = [143];

        # GTK apps need a real theme package; DMS only manages the live color overlay.
        home.packages = [pkgs.adw-gtk3];

        # Bootstrap DMS settings + terminal theme stubs (compositor-agnostic).
        home.activation.dmsBootstrap = {
          after = ["linkGeneration"];
          before = [];
          data = ''
            ${restoreDmsBackup "${config.xdg.configHome}/DankMaterialShell/settings.json"}
            ${restoreDmsBackup "${config.xdg.stateHome}/DankMaterialShell/session.json"}
            ${bootstrapDmsSettings}

            ${installMissingFile dmsTerminalFiles.alacritty "${config.xdg.configHome}/alacritty/dank-theme.toml"}
            ${installMissingFile dmsTerminalFiles.kittyTheme "${config.xdg.configHome}/kitty/dank-theme.conf"}
            ${installMissingFile dmsTerminalFiles.kittyTabs "${config.xdg.configHome}/kitty/dank-tabs.conf"}
            ${installMissingFile dmsTerminalFiles.foot "${config.xdg.configHome}/foot/dank-colors.ini"}
          '';
        };

        # DankSearch — indexed file search
        programs.dsearch.enable = true;

        # DMS has its own bluetooth panel and notification center.
        xdg.configFile."autostart/blueman.desktop".text = ''
          [Desktop Entry]
          Hidden=true
        '';

        # Rescue oneshot — if DMS crash-loops into start-rate limiting, wait for
        # outputs to settle, clear failed state, then restart shell.
        systemd.user.services.dms-rescue = {
          Unit = {
            Description = "DMS crash rescue — delayed restart after rate-limit exhaustion";
            PartOf = [config.programs.dank-material-shell.systemd.target];
            Requisite = [config.programs.dank-material-shell.systemd.target];
            After = [config.programs.dank-material-shell.systemd.target];
          };
          Service = {
            Type = "oneshot";
            # Allow the owning compositor/session target to settle before retrying.
            # A normal target shutdown stops this unit instead of resurrecting DMS.
            ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 8; systemctl --user reset-failed dms.service 2>/dev/null; exec systemctl --user start dms.service'";
          };
        };
      }

      # ── Niri compositor integration ──
      (mkIf niriEnabled {
        programs.dank-material-shell.niri = {
          enableSpawn = false;
          includes = {
            enable = true;
            filesToInclude = niriFilesToInclude;
          };
        };

        # Select the compositor lifecycle through DMS's existing target seam.
        # Other compositor integrations can choose their own owning target.
        programs.dank-material-shell.systemd.target = "niri.service";

        programs.niri.settings.environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
        };

        xdg.configFile."niri/dms/blur.kdl".source = dmsNiriFiles.blur;

        # Bootstrap niri-specific DMS config fragments.
        home.activation.dmsNiriBootstrap = {
          after = ["writeBoundary"];
          before = [];
          data = ''
            dms_dir=${escapeShellArg "${config.xdg.configHome}/niri/dms"}
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$dms_dir"

            ${concatStringsSep "\n" (map installMissingNiriFile bootstrappedNiriFiles)}
          '';
        };
      })
    ];
  };
}
