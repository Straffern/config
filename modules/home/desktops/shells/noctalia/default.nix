{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkForce mkIf mkMerge;
  cfg = config.${namespace}.desktops.shells.noctalia;

  niriEnabled = config.${namespace}.desktops.niri.enable or false;
  hyprlandEnabled = config.${namespace}.desktops.hyprland.enable or false;
in {
  options.${namespace}.desktops.shells.noctalia = {
    enable = mkEnableOption "Noctalia desktop shell";
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Core: compositor-agnostic Noctalia config ──
    {
      # Noctalia manages its own runtime theming — Nix module just enables it.
      programs.noctalia-shell = {
        enable = true;
        settings = {
          general = {
            radiusRatio = 0.2;
          };
        };
      };

      # Noctalia owns all runtime theming; suppress conflicting systems.
      ${namespace} = {
        styles.stylix.enable = mkForce false;
        services.kdeconnect.indicator = false;
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
  ]);
}
