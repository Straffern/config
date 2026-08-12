{den, ...}: {
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia-shell";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.desktop.noctalia.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      mkIf
      mkMerge
      ;

    niriEnabled = config.programs.niri.enable or false;
    hyprlandEnabled = config.wayland.windowManager.hyprland.enable or false;
  in
    mkMerge [
      # ── Core: compositor-agnostic Noctalia config ──
      {
        # Noctalia manages its own runtime theming — Nix module just enables it.
        programs.noctalia = {
          enable = true;
          settings = {
            general = {
              radiusRatio = 0.2;
            };
          };
        };

        # Noctalia has its own bluetooth panel and notification center;
        # suppress legacy tray applets that render broken under Noctalia.
        xdg.configFile."autostart/blueman.desktop".text = ''
          [Desktop Entry]
          Hidden=true
        '';
      }

      # ── Niri compositor integration ──
      (mkIf niriEnabled {
        # qt6ct gives dedicated Qt theming control; Noctalia generates qt6ct color schemes.
        programs.niri.settings.environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
        };
      })

      # ── Hyprland compositor integration ──
      (mkIf hyprlandEnabled {
        wayland.windowManager.hyprland.settings.env = [
          "QT_QPA_PLATFORMTHEME,qt6ct"
          "QT_QPA_PLATFORMTHEME_QT6,qt6ct"
        ];
      })
    ];
}
