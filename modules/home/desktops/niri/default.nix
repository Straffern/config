{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.${namespace}.desktops.niri;

  # Prefer kitty whenever available; fall back only if it is disabled everywhere.
  terminalCommand =
    if config.${namespace}.cli.terminals.kitty.enable
    then "kitty"
    else if config.${namespace}.cli.terminals.alacritty.enable
    then "alacritty"
    else if config.${namespace}.cli.terminals.foot.enable
    then "foot"
    else "kitty";
in {
  options.${namespace}.desktops.niri = {
    enable = mkEnableOption "Niri Wayland compositor";
    terminalCommand = mkOption {
      type = types.str;
      readOnly = true;
      description = "Terminal emulator command selected by desktop preference order";
      default = terminalCommand;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          config.${namespace}.cli.terminals.kitty.enable
          || config.${namespace}.cli.terminals.alacritty.enable
          || config.${namespace}.cli.terminals.foot.enable;
        message = "asgaard.desktops.niri requires at least one terminal emulator enabled";
      }
    ];

    # Output profile switching (dock/undock) — compositor-agnostic, kanshi speaks wlr-output-management.
    ${namespace}.desktops.addons.kanshi.enable = true;

    # Keep HM niri schema aligned with the compositor actually installed by nixpkgs.
    programs.niri = {
      package = pkgs.niri;
      settings = {
        # input.focus-follows-mouse.enable = true;
        input.keyboard.xkb = {
          layout = "us,dk";
          options = "grp:alts_toggle";
        };

        # Screencasting: dynamic cast target + windowed fullscreen (niri ≥25.05).
        # S = screencast; modifier escalation: Shift=window, Ctrl+Shift=monitor, Ctrl=clear.
        binds = with config.lib.niri.actions; {
          "Mod+Shift+S" = {
            action = set-dynamic-cast-window;
            hotkey-overlay.title = "Cast Window";
          };
          "Mod+Ctrl+Shift+S" = {
            action = set-dynamic-cast-monitor;
            hotkey-overlay.title = "Cast Monitor";
          };
          "Mod+Ctrl+S" = {
            action = clear-dynamic-cast-target;
            hotkey-overlay.title = "Stop Cast";
          };
          "Mod+Ctrl+Shift+F" = {
            action = toggle-windowed-fullscreen;
            hotkey-overlay.title = "Windowed Fullscreen";
          };
        };

        # Red indicator on windows actively targeted by a screencast.
        window-rules = [
          {
            matches = [{is-window-cast-target = true;}];
            focus-ring = {
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };
            border = {
              inactive.color = "#7d0d2d";
            };
            shadow = {
              color = "#7d0d2d70";
            };
            tab-indicator = {
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };
          }
        ];
      };
    };

    # Prefer portal for xdg-open (NixOS programs.niri handles portal packages)
    xdg.portal.xdgOpenUsePortal = true;
  };
}
