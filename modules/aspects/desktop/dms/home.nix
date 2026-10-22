{
  den,
  inputs,
  ...
}: {
  flake-file.inputs = {
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
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
  };
  den.aspects.desktop.dms.homeManager = {
    config,
    host,
    lib,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      mkForce
      mkIf
      mkMerge
      ;

    niriEnabled = config.programs.niri.enable or false;
    hyprlandEnabled = host.hasAspect den.aspects.desktop.hyprland;
    dmsDesktops = lib.optional niriEnabled "niri" ++ lib.optional hyprlandEnabled "Hyprland";

    terminalCommand = "xdg-terminal-exec";

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
        keyboardLayouts = "us,dk";
        keyboardOptions = "grp:alts_toggle";
        iconThemeDark = "Papirus-Dark";
        iconThemeLight = "Papirus-Dark";
        acProfileName = "1";
        batteryProfileName = "0";
      }
    );

    # --- Terminal theme stubs (compositor-agnostic) ---

    dmsTerminalFiles = {
      alacritty = pkgs.writeText "dms-alacritty-theme.toml" "";
      kittyTheme = pkgs.writeText "dms-kitty-theme.conf" "";
      kittyTabs = pkgs.writeText "dms-kitty-tabs.conf" "";
      foot = pkgs.writeText "dms-foot-colors.ini" "";
    };

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
      input = pkgs.writeText "dms-niri-input.kdl" (
        builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-input.kdl"
      );
      cursor = pkgs.writeText "dms-niri-cursor.kdl" "";
      windowrules = pkgs.writeText "dms-niri-windowrules.kdl" "";
      blur = pkgs.writeText "dms-niri-blur.kdl" dmsNiriLayerRules;

      wpblur = pkgs.writeText "dms-niri-wpblur.kdl" (
        builtins.readFile "${inputs.dms}/quickshell/Services/niri-wpblur.kdl"
      );
    };
    # binds-user, layout, outputs, cursor and windowrules are dotfiles-owned links (hyprland aspect).
    dmsHyprFiles = lib.genAttrs ["colors" "binds"] (
      name:
        pkgs.writeText "dms-hypr-${name}.lua" (
          builtins.replaceStrings ["{{TERMINAL_COMMAND}}"] [terminalCommand] (
            builtins.readFile "${inputs.dms}/core/internal/config/embedded/hypr-${name}.lua"
          )
        )
    );

    castRule = ./_assets/cast-windowrule.kdl;
    keybinds = {
      "Mod+Shift+S" = {
        action = "set-dynamic-cast-window";
        description = "Cast Window";
      };
      "Mod+Ctrl+Shift+S" = {
        action = "set-dynamic-cast-monitor";
        description = "Cast Monitor";
      };
      "Mod+Ctrl+S" = {
        action = "clear-dynamic-cast-target";
        description = "Stop Cast";
      };
      "Mod+Ctrl+Shift+F" = {
        action = "toggle-windowed-fullscreen";
        description = "Windowed Fullscreen";
      };
    };
    autostart = name: command: hidden:
      pkgs.writeText "dms-${name}.desktop" ''
        [Desktop Entry]
        Type=Application
        Name=${name}
        Exec=${command}
        Hidden=${lib.boolToString hidden}
      '';
    configFiles =
      {
        "DankMaterialShell/settings.json" = dmsSettingsBootstrap;
        "alacritty/dank-theme.toml" = dmsTerminalFiles.alacritty;
        "kitty/dank-theme.conf" = dmsTerminalFiles.kittyTheme;
        "kitty/dank-tabs.conf" = dmsTerminalFiles.kittyTabs;
        "foot/dank-colors.ini" = dmsTerminalFiles.foot;
        "gtk-3.0/settings.ini" = pkgs.writeText "dms-gtk-settings.ini" "[Settings]\ngtk-icon-theme-name=Papirus-Dark\n";
        "gtk-4.0/settings.ini" = configFiles."gtk-3.0/settings.ini";
        "autostart/blueman.desktop" = autostart "Bluetooth" "blueman-applet" true;
        "xdg-terminals.list" = pkgs.writeText "dms-xdg-terminals.list" "kitty.desktop\n";
      }
      // lib.optionalAttrs niriEnabled (
        lib.mapAttrs' (name: source: lib.nameValuePair "niri/dms/${name}.kdl" source) dmsNiriFiles
      )
      // lib.optionalAttrs hyprlandEnabled (
        lib.mapAttrs' (name: source: lib.nameValuePair "hypr/dms/${name}.lua" source) dmsHyprFiles
      );
    bootstrapManifest = pkgs.writeText "dms-bootstrap.json" (builtins.toJSON {
      inherit keybinds castRule;
      shellRule = ./_assets/shell-windowrule.kdl;
      niri = niriEnabled;
      niriBin = lib.optionalString niriEnabled "${config.programs.niri.package}/bin";
      dms = lib.getExe config.programs.dank-material-shell.package;
      configHome = config.xdg.configHome;
      marker = "${config.xdg.stateHome}/DankMaterialShell/hm-ownership-migrated";
      seeded = "${config.xdg.stateHome}/DankMaterialShell/hm-seeded.json";
      settings = "${config.xdg.configHome}/DankMaterialShell/settings.json";
      replaceStoreLinks = [
        "${config.xdg.configHome}/autostart/blueman.desktop"
        "${config.xdg.configHome}/niri/dms/blur.kdl"
      ];
      files =
        lib.mapAttrs' (name: source: lib.nameValuePair "${config.xdg.configHome}/${name}" source) configFiles
        // {
          "${config.xdg.stateHome}/DankMaterialShell/session.json" = pkgs.writeText "dms-session.json" "{}";
        };
    });
    bootstrapCommand = "${lib.getExe pkgs.python3} ${./_bootstrap.py} ${bootstrapManifest}";
  in {
    imports = [
      inputs.dms.homeModules.dank-material-shell
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
                patch --fuzz=0 --no-backup-if-mismatch -d "$out/share/quickshell/dms" -p1 < ${./_assets/hyprland-desc-identifier.patch}
              '';
          });
          systemd.enable = true;
          systemd.target = "graphical-session.target";
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
            ConditionEnvironment = map (desktop: "|XDG_CURRENT_DESKTOP=${desktop}") dmsDesktops;
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
            OnFailure = ["dms-rescue.service"];
          };

          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
            RestartSec = "3s";
            SuccessExitStatus = mkForce [143 "TEMPFAIL"];
            TimeoutStopSec = 10;
          };
        };
        systemd.user.services.dcal.Service.SuccessExitStatus = [143];

        # GTK apps need a real theme package; DMS only manages the live color overlay.
        # DMS lists cursor themes from XDG_DATA_DIRS and ships none itself.
        home.packages = with pkgs; [
          adw-gtk3
          xdg-terminal-exec
          bibata-cursors
          phinger-cursors
          rose-pine-cursor
          capitaine-cursors-themed
        ];

        # Detach retired HM links before linkGeneration removes them.
        home.activation.dmsBootstrapFiles = {
          after = ["writeBoundary"];
          before = ["linkGeneration"];
          data = "$DRY_RUN_CMD ${bootstrapCommand} --files-only";
        };
        home.activation.dmsBootstrap = {
          after = ["linkGeneration"];
          before = ["reloadSystemd"];
          data = "$DRY_RUN_CMD ${bootstrapCommand}";
        };

        assertions = [
          {
            assertion = builtins.all (name: !(config.xdg.configFile.${name}.enable or false)) (builtins.attrNames configFiles);
            message = "DMS settings files must be writable bootstrap state, not Home Manager links.";
          }
        ];

        # DankSearch — indexed file search
        programs.dsearch.enable = true;

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
        xdg.configFile.niri-config.target = mkForce "niri/hm.kdl";
        xdg.configFile.niri-config-dms = {
          target = "niri/config.kdl";
          source = config.lib.mutableSources.link ./_config/niri/config.kdl;
        };
      })

      # ── Hyprland compositor integration ──
      # DMS rewrites its fragments in place (`cat >`, os.WriteFile), so edits through these links land in the repo.
      (mkIf hyprlandEnabled {
        xdg.configFile = lib.genAttrs (["hypr/shell.lua"] ++ map (name: "hypr/dms/${name}.lua") ["binds-user" "layout" "outputs" "cursor" "windowrules"]) (
          target: {source = config.lib.mutableSources.link (./_config + "/${target}");}
        );
      })
    ];
  };
}
