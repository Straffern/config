{
  pkgs,
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.multiplexers.zellij;
  dmsEnabled = config.programs.dank-material-shell.enable;
  stylixPalette = config.lib.stylix.colors.withHashtag;
  fallbackPalette = {
    base00 = "#1e1e2e";
    base01 = "#181825";
    base02 = "#313244";
    base03 = "#45475a";
    base04 = "#585b70";
    base05 = "#cdd6f4";
    base06 = "#f5e0dc";
    base07 = "#bac2de";
    base08 = "#f38ba8";
    base09 = "#fab387";
    base0A = "#f9e2af";
    base0B = "#a6e3a1";
    base0C = "#94e2d5";
    base0D = "#89b4fa";
    base0E = "#cba6f7";
    base0F = "#f2cdcd";
  };

  dmsConfigSource = pkgs.writeText "zellij-config-dms.kdl" (
    builtins.replaceStrings
    [''theme "catppuccin-mocha"'']
    [''theme "dank-shell"'']
    (builtins.readFile ./config.kdl)
  );

  dmsZellijThemeTemplate = pkgs.writeText "dms-zellij-theme-template.kdl" (builtins.readFile ./dms-theme.kdl);
  dmsZellijLayoutTemplate = pkgs.writeText "dms-zellij-layout-template.kdl" (
    builtins.replaceStrings
    ["__ZJSTATUS_WASM__"]
    ["${pkgs.zjstatus}/bin/zjstatus.wasm"]
    (builtins.readFile ./dms-layout.kdl)
  );

  mkZellijTheme = p: ''
    themes {
        dank-shell {
            text_unselected {
                base "${p.base05}"
                background "${p.base00}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            text_selected {
                base "${p.base05}"
                background "${p.base02}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            ribbon_unselected {
                base "${p.base00}"
                background "${p.base07}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base05}"
                emphasis_2 "${p.base0D}"
                emphasis_3 "${p.base0E}"
            }
            ribbon_selected {
                base "${p.base00}"
                background "${p.base0B}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0A}"
                emphasis_2 "${p.base0E}"
                emphasis_3 "${p.base0D}"
            }
            table_title {
                base "${p.base0B}"
                background "${p.base00}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            table_cell_unselected {
                base "${p.base05}"
                background "${p.base00}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            table_cell_selected {
                base "${p.base05}"
                background "${p.base02}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            list_unselected {
                base "${p.base05}"
                background "${p.base00}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            list_selected {
                base "${p.base05}"
                background "${p.base02}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0B}"
                emphasis_3 "${p.base0E}"
            }
            frame_selected {
                base "${p.base0D}"
                background "${p.base00}"
                emphasis_0 "${p.base08}"
                emphasis_1 "${p.base0C}"
                emphasis_2 "${p.base0E}"
                emphasis_3 "${p.base00}"
            }
            frame_highlight {
                base "${p.base08}"
                background "${p.base00}"
                emphasis_0 "${p.base0E}"
                emphasis_1 "${p.base08}"
                emphasis_2 "${p.base08}"
                emphasis_3 "${p.base08}"
            }
            exit_code_success {
                base "${p.base0B}"
                background "${p.base00}"
                emphasis_0 "${p.base0C}"
                emphasis_1 "${p.base00}"
                emphasis_2 "${p.base0E}"
                emphasis_3 "${p.base0D}"
            }
            exit_code_error {
                base "${p.base08}"
                background "${p.base00}"
                emphasis_0 "${p.base0A}"
                emphasis_1 "${p.base00}"
                emphasis_2 "${p.base00}"
                emphasis_3 "${p.base00}"
            }
            multiplayer_user_colors {
                player_1 "${p.base0E}"
                player_2 "${p.base0D}"
                player_3 "${p.base00}"
                player_4 "${p.base0A}"
                player_5 "${p.base0C}"
                player_6 "${p.base00}"
                player_7 "${p.base08}"
                player_8 "${p.base00}"
                player_9 "${p.base00}"
                player_10 "${p.base00}"
            }
        }
    }
  '';

  mkZellijLayout = p: ''
    layout {
        swap_tiled_layout name="vertical" {
            tab max_panes=5 {
                pane split_direction="vertical" {
                    pane
                    pane { children; }
                }
            }
            tab max_panes=8 {
                pane split_direction="vertical" {
                    pane { children; }
                    pane { pane; pane; pane; pane; }
                }
            }
            tab max_panes=12 {
                pane split_direction="vertical" {
                    pane { children; }
                    pane { pane; pane; pane; pane; }
                    pane { pane; pane; pane; pane; }
                }
            }
        }

        swap_tiled_layout name="horizontal" {
            tab max_panes=5 {
                pane
                pane
            }
            tab max_panes=8 {
                pane {
                    pane split_direction="vertical" { children; }
                    pane split_direction="vertical" { pane; pane; pane; pane; }
                }
            }
            tab max_panes=12 {
                pane {
                    pane split_direction="vertical" { children; }
                    pane split_direction="vertical" { pane; pane; pane; pane; }
                    pane split_direction="vertical" { pane; pane; pane; pane; }
                }
            }
        }

        swap_tiled_layout name="stacked" {
            tab min_panes=5 {
                pane split_direction="vertical" {
                    pane
                    pane stacked=true { children; }
                }
            }
        }

        swap_floating_layout name="staggered" {
            floating_panes
        }

        swap_floating_layout name="enlarged" {
            floating_panes max_panes=10 {
                pane { x "5%"; y 1; width "90%"; height "90%"; }
                pane { x "5%"; y 2; width "90%"; height "90%"; }
                pane { x "5%"; y 3; width "90%"; height "90%"; }
                pane { x "5%"; y 4; width "90%"; height "90%"; }
                pane { x "5%"; y 5; width "90%"; height "90%"; }
                pane { x "5%"; y 6; width "90%"; height "90%"; }
                pane { x "5%"; y 7; width "90%"; height "90%"; }
                pane { x "5%"; y 8; width "90%"; height "90%"; }
                pane { x "5%"; y 9; width "90%"; height "90%"; }
                pane focus=true { x 10; y 10; width "90%"; height "90%"; }
            }
        }

        swap_floating_layout name="spread" {
            floating_panes max_panes=1 {
                pane {y "50%"; x "50%"; }
            }
            floating_panes max_panes=2 {
                pane { x "1%"; y "25%"; width "45%"; }
                pane { x "50%"; y "25%"; width "45%"; }
            }
            floating_panes max_panes=3 {
                pane focus=true { y "55%"; width "45%"; height "45%"; }
                pane { x "1%"; y "1%"; width "45%"; }
                pane { x "50%"; y "1%"; width "45%"; }
            }
            floating_panes max_panes=4 {
                pane { x "1%"; y "55%"; width "45%"; height "45%"; }
                pane focus=true { x "50%"; y "55%"; width "45%"; height "45%"; }
                pane { x "1%"; y "1%"; width "45%"; height "45%"; }
                pane { x "50%"; y "1%"; width "45%"; height "45%"; }
            }
        }

        default_tab_template {
            pane size=2 borderless=true {
                plugin location="file://${pkgs.zjstatus}/bin/zjstatus.wasm" {
                    format_left   "{mode}#[bg=${p.base00}] {tabs}"
                    format_center ""
                    format_right  "#[bg=${p.base00},fg=${p.base0D}]#[bg=${p.base0D},fg=${p.base00},bold] #[bg=${p.base02},fg=${p.base05},bold] {session} #[bg=${p.base03},fg=${p.base05},bold]"
                    format_space  ""
                    format_hide_on_overlength "true"
                    format_precedence "crl"

                    border_enabled  "false"
                    border_char     "─"
                    border_format   "#[fg=${p.base03}]{char}"
                    border_position "top"

                    mode_normal        "#[bg=${p.base0B},fg=${p.base00},bold] NORMAL#[bg=${p.base03},fg=${p.base0B}]█"
                    mode_locked        "#[bg=${p.base04},fg=${p.base00},bold] LOCKED #[bg=${p.base03},fg=${p.base04}]█"
                    mode_resize        "#[bg=${p.base08},fg=${p.base00},bold] RESIZE#[bg=${p.base03},fg=${p.base08}]█"
                    mode_pane          "#[bg=${p.base0D},fg=${p.base00},bold] PANE#[bg=${p.base03},fg=${p.base0D}]█"
                    mode_tab           "#[bg=${p.base07},fg=${p.base00},bold] TAB#[bg=${p.base03},fg=${p.base07}]█"
                    mode_scroll        "#[bg=${p.base0A},fg=${p.base00},bold] SCROLL#[bg=${p.base03},fg=${p.base0A}]█"
                    mode_enter_search  "#[bg=${p.base0D},fg=${p.base00},bold] ENT-SEARCH#[bg=${p.base03},fg=${p.base0D}]█"
                    mode_search        "#[bg=${p.base0D},fg=${p.base00},bold] SEARCH#[bg=${p.base03},fg=${p.base0D}]█"
                    mode_rename_tab    "#[bg=${p.base07},fg=${p.base00},bold] RENAME-TAB#[bg=${p.base03},fg=${p.base07}]█"
                    mode_rename_pane   "#[bg=${p.base0D},fg=${p.base00},bold] RENAME-PANE#[bg=${p.base03},fg=${p.base0D}]█"
                    mode_session       "#[bg=${p.base0E},fg=${p.base00},bold] SESSION#[bg=${p.base03},fg=${p.base0E}]█"
                    mode_move          "#[bg=${p.base0F},fg=${p.base00},bold] MOVE#[bg=${p.base03},fg=${p.base0F}]█"
                    mode_prompt        "#[bg=${p.base0D},fg=${p.base00},bold] PROMPT#[bg=${p.base03},fg=${p.base0D}]█"
                    mode_tmux          "#[bg=${p.base09},fg=${p.base00},bold] TMUX#[bg=${p.base03},fg=${p.base09}]█"

                    tab_normal              "#[bg=${p.base03},fg=${p.base0D}]█#[bg=${p.base0D},fg=${p.base00},bold]{index} #[bg=${p.base00},fg=${p.base05},bold] {name}{floating_indicator}#[bg=${p.base03},fg=${p.base00},bold]█"
                    tab_normal_fullscreen   "#[bg=${p.base03},fg=${p.base0D}]█#[bg=${p.base0D},fg=${p.base00},bold]{index} #[bg=${p.base00},fg=${p.base05},bold] {name}{fullscreen_indicator}#[bg=${p.base03},fg=${p.base00},bold]█"
                    tab_normal_sync         "#[bg=${p.base03},fg=${p.base0D}]█#[bg=${p.base0D},fg=${p.base00},bold]{index} #[bg=${p.base00},fg=${p.base05},bold] {name}{sync_indicator}#[bg=${p.base03},fg=${p.base00},bold]█"

                    tab_active              "#[bg=${p.base03},fg=${p.base09}]█#[bg=${p.base09},fg=${p.base00},bold]{index} #[bg=${p.base00},fg=${p.base05},bold] {name}{floating_indicator}#[bg=${p.base03},fg=${p.base00},bold]█"
                    tab_active_fullscreen   "#[bg=${p.base03},fg=${p.base09}]█#[bg=${p.base09},fg=${p.base00},bold]{index} #[bg=${p.base00},fg=${p.base05},bold] {name}{fullscreen_indicator}#[bg=${p.base03},fg=${p.base00},bold]█"
                    tab_active_sync         "#[bg=${p.base03},fg=${p.base09}]█#[bg=${p.base09},fg=${p.base00},bold]{index} #[bg=${p.base00},fg=${p.base05},bold] {name}{sync_indicator}#[bg=${p.base03},fg=${p.base00},bold]█"

                    tab_separator           "#[bg=${p.base00}] "

                    tab_sync_indicator       " "
                    tab_fullscreen_indicator " 󰊓"
                    tab_floating_indicator   " 󰹙"

                    command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                    command_git_branch_format      "#[fg=blue] {stdout} "
                    command_git_branch_interval    "10"
                    command_git_branch_rendermode  "static"

                    datetime        "#[fg=${p.base03},bold] {format} "
                    datetime_format "%A, %d %b %Y %H:%M"
                    datetime_timezone "Europe/London"
                }
            }
            children
        }
    }
  '';

  dmsZellijThemeBootstrap = pkgs.writeText "dms-zellij-theme-bootstrap.kdl" (mkZellijTheme fallbackPalette);
  dmsZellijLayoutBootstrap = pkgs.writeText "dms-zellij-layout-bootstrap.kdl" (mkZellijLayout fallbackPalette);

  sesh = pkgs.writeScriptBin "sesh" ''
    #!/usr/bin/env sh

    # Taken from https://github.com/zellij-org/zellij/issues/884#issuecomment-1851136980
    # select a directory using zoxide
    ZOXIDE_RESULT=$(zoxide query --interactive)
    # checks whether a directory has been selected
    if [ -z "$ZOXIDE_RESULT" ]; then
      # if there was no directory, select returns without executing
      exit 0
    fi
    # extracts the directory name from the absolute path
    SESSION_TITLE=$(basename "$ZOXIDE_RESULT")
    CURRENT_SESSION="$ZELLIJ_SESSION_NAME"

    # get the list of sessions
    SESSION_LIST=$(zellij list-sessions -s)

    # checks if SESSION_TITLE is in the session list
    if printf '%s\n' "$SESSION_LIST" | grep -Fxq "$SESSION_TITLE"; then
      # zellij panics when trying to attach to the current session
      if [ -n "$ZELLIJ" ] && [ "$SESSION_TITLE" = "$CURRENT_SESSION" ]; then
        zellij action new-tab --name "$SESSION_TITLE" --cwd "$ZOXIDE_RESULT"
        exit 0
      fi

      # if so, attach to existing session
      zellij attach "$SESSION_TITLE"
    else
      # if not, create a new session
      echo "Creating new session $SESSION_TITLE and CD $ZOXIDE_RESULT"
      cd "$ZOXIDE_RESULT" || exit 1
      zellij attach -c "$SESSION_TITLE"
    fi
  '';
in {
  options.${namespace}.cli.multiplexers.zellij = {
    enable = mkEnableOption "Zellij";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
      sesh
    ];

    xdg.configFile."zellij/config.kdl".source =
      if dmsEnabled
      then dmsConfigSource
      else config.lib.asgaard.managedSource ./config.kdl;

    xdg.configFile."zellij/layouts/default.kdl" = mkIf (!dmsEnabled) {
      text = mkZellijLayout stylixPalette;
    };

    xdg.configFile."matugen/dms/configs/zellij-theme.toml" = mkIf dmsEnabled {
      text = ''
        [templates.dmszellijtheme]
        input_path = '${dmsZellijThemeTemplate}'
        output_path = '${config.xdg.configHome}/zellij/themes/dank-shell.kdl'
      '';
    };

    xdg.configFile."matugen/dms/configs/zellij-layout.toml" = mkIf dmsEnabled {
      text = ''
        [templates.dmszellijlayout]
        input_path = '${dmsZellijLayoutTemplate}'
        output_path = '${config.xdg.configHome}/zellij/layouts/default.kdl'
      '';
    };

    home.activation.dmsZellijBootstrap = mkIf dmsEnabled {
      after = ["writeBoundary"];
      before = [];
      data = ''
        if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/zellij/themes/dank-shell.kdl"} ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
            ${lib.escapeShellArg "${dmsZellijThemeBootstrap}"} \
            ${lib.escapeShellArg "${config.xdg.configHome}/zellij/themes/dank-shell.kdl"}
        fi

        if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/zellij/layouts/default.kdl"} ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
            ${lib.escapeShellArg "${dmsZellijLayoutBootstrap}"} \
            ${lib.escapeShellArg "${config.xdg.configHome}/zellij/layouts/default.kdl"}
        fi
      '';
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = false;
    };
  };
}
