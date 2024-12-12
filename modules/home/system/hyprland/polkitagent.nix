{ inputs, pkgs, ... }: {
  # TODO: try add hyprpolkitagent to overlays.
  home.packages = [ pkgs.hyprpolkitagent ];

  wayland.windowManager.hyprland.settings.exec-once =
    [ "systemctl --user start hyprpolkitagent" ];
}
