{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    escapeShellArg
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    ;
  cfg = config.${namespace}.desktops.shells.dms;

  niriEnabled = config.${namespace}.desktops.niri.enable or false;
  hyprlandEnabled = config.${namespace}.desktops.hyprland.enable or false;

  terminalCommand =
    if niriEnabled
    then config.${namespace}.desktops.niri.terminalCommand
    else "kitty";

  # --- DMS settings bootstrap (compositor-agnostic) ---

  dmsSettingsBootstrap = pkgs.writeText "dms-settings-bootstrap.json" (
    builtins.toJSON {
      blurEnabled = true;
      gtkThemingEnabled = true;
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
  options.${namespace}.desktops.shells.dms = {
    enable = mkEnableOption "DankMaterialShell desktop shell";
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Core: compositor-agnostic DMS config ──
    {
      programs.dank-material-shell = {
        enable = true;
        systemd.enable = true;
        enableSystemMonitoring = true;
        enableDynamicTheming = true;
        enableClipboardPaste = true;
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
          TimeoutStopSec = 10;
        };
      };

      # GTK apps need a real theme package; DMS only manages the live color overlay.
      home.packages = [pkgs.adw-gtk3];

      # DMS owns all runtime theming; stylix has no role with this shell.
      ${namespace} = {
        styles.stylix.enable = mkForce false;
        services.kdeconnect.indicator = false;
      };

      # Bootstrap DMS settings + terminal theme stubs (compositor-agnostic).
      home.activation.dmsBootstrap = {
        after = ["writeBoundary"];
        before = [];
        data = ''
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
        Unit.Description = "DMS crash rescue — delayed restart after rate-limit exhaustion";
        Service = {
          Type = "oneshot";
          # 8s delay: niri needs time to settle outputs after dock/undock/suspend.
          # reset-failed clears the rate-limit counter so the next start succeeds.
          ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 8 && systemctl --user reset-failed dms.service 2>/dev/null; exec systemctl --user start dms.service'";
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

      # Match `systemctl --user add-wants niri.service dms` semantics.
      systemd.user.services.dms.Install.WantedBy = mkForce ["niri.service"];

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

    # ── Hyprland compositor integration ──
    (mkIf hyprlandEnabled {
      wayland.windowManager.hyprland.settings = {
        env = [
          "QT_QPA_PLATFORMTHEME,qt6ct"
          "QT_QPA_PLATFORMTHEME_QT6,qt6ct"
        ];
        exec-once = ["dms run"];
      };
    })
  ]);
}
