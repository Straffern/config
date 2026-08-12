{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.niri = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.desktop.niri = {
    includes = [den.aspects.desktop.addons.kanshi];
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (lib) mkForce;
      niriBlurAppendix = ''
        blur {
          passes 3
          offset 3.0
          noise 0.02
          saturation 1.5
        }
      '';
    in {
      imports = [inputs.niri.homeModules.niri];
      programs.niri.enable = true;
      # Use same updated niri input for runtime package and config validation.
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

          # Red indicator on windows actively targeted by screencast.
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

      xdg.configFile.niri-config.source = mkForce (
        inputs.niri.lib.internal.validated-config-for pkgs config.programs.niri.package ''
          ${config.programs.niri.finalConfig}
          ${niriBlurAppendix}
        ''
      );

      # Prefer portal for xdg-open (NixOS programs.niri handles portal packages)
      xdg.portal.xdgOpenUsePortal = true;
    };
  };
}
