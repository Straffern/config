{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) concatStringsSep escapeShellArg mkEnableOption mkForce mkIf mkMerge;
  cfg = config.${namespace}.desktops.shells.dms;

  niriEnabled = config.${namespace}.desktops.niri.enable or false;
  hyprlandEnabled = config.${namespace}.desktops.hyprland.enable or false;

  terminalCommand =
    if niriEnabled
    then config.${namespace}.desktops.niri.terminalCommand
    else "kitty";

  # --- DMS settings bootstrap (compositor-agnostic) ---

  dmsSettingsBootstrap = pkgs.writeText "dms-settings-bootstrap.json" (builtins.toJSON {
    gtkThemingEnabled = true;
    matugenTemplateNeovim = true;
  });

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
          (if has("gtkThemingEnabled") then . else . + { gtkThemingEnabled: true } end)
          | (if has("matugenTemplateNeovim") then . else . + { matugenTemplateNeovim: true } end)
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

  dmsNiriFiles = {
    colors = pkgs.writeText "dms-niri-colors.kdl" (builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-colors.kdl");
    layout = pkgs.writeText "dms-niri-layout.kdl" (builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-layout.kdl");
    alttab = pkgs.writeText "dms-niri-alttab.kdl" (builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-alttab.kdl");
    binds = pkgs.writeText "dms-niri-binds.kdl" (
      builtins.replaceStrings
      ["{{TERMINAL_COMMAND}}"]
      [terminalCommand]
      (builtins.readFile "${inputs.dms}/core/internal/config/embedded/niri-binds.kdl")
    );
    outputs = pkgs.writeText "dms-niri-outputs.kdl" "";
    cursor = pkgs.writeText "dms-niri-cursor.kdl" "";
    windowrules = pkgs.writeText "dms-niri-windowrules.kdl" "";
    wpblur = pkgs.writeText "dms-niri-wpblur.kdl" (builtins.readFile "${inputs.dms}/quickshell/Services/niri-wpblur.kdl");
  };

  niriFilesToInclude = [
    "colors"
    "layout"
    "alttab"
    "binds"
    "outputs"
    "cursor"
    "windowrules"
    "wpblur"
  ];

  installMissingNiriFile = name:
    installMissingFile dmsNiriFiles.${name} "${config.xdg.configHome}/niri/dms/${name}.kdl";
in {
  options.${namespace}.desktops.shells.dms = {
    enable = mkEnableOption "DankMaterialShell desktop shell";
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Core: compositor-agnostic DMS config ──
    {
      programs.dank-material-shell = {
        enable = true;
        systemd.enable = false;
        enableSystemMonitoring = true;
        enableDynamicTheming = true;
        enableClipboardPaste = true;
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
    }

    # ── Niri compositor integration ──
    (mkIf niriEnabled {
      programs.dank-material-shell.niri = {
        enableSpawn = true;
        includes = {
          enable = true;
          filesToInclude = niriFilesToInclude;
        };
      };

      programs.niri.settings.environment = {
        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
      };

      # Bootstrap niri-specific DMS config fragments.
      home.activation.dmsNiriBootstrap = {
        after = ["writeBoundary"];
        before = [];
        data = ''
          dms_dir=${escapeShellArg "${config.xdg.configHome}/niri/dms"}
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$dms_dir"

          ${concatStringsSep "\n" (map installMissingNiriFile niriFilesToInclude)}
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
