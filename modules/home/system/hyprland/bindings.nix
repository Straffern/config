{ pkgs }: {
  wayland.windowManager.hyprland.settings = {

    bind = [
      "$mainMod, RETURN, exec, foot"
      "$mainMod, Q, killactive,"
      "$mainMod, SPACE, togglefloating,"
      "$mainMod, P, exec, wofi --show drun"
      "$mainMod, F, fullscreen"
      "$mainMod, TAB, pseudo"
      "$mainMod_SHIFT, E, exec, wlogout -b 1 -p layer-shell"
      "$mainMod_SHIFT, Q, exec, gtklock"
      "$mainMod_SHIFT, C, exec, wallpaper"
      ", code:107, exec, screenshot"
      "$mainMod, code:107, exec, screenshot-edit"
      "$mainMod, h, movefocus, l"
      "$mainMod, l, movefocus, r"
      "$mainMod, k, movefocus, u"
      "$mainMod, j, movefocus, d"
      "$mainMod_SHIFT, h, movewindow, l"
      "$mainMod_SHIFT, l, movewindow, r"
      "$mainMod_SHIFT, k, movewindow, u"
      "$mainMod_SHIFT, j, movewindow, d"
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPrev, exec, playerctl previous"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioStop, exec, playerctl stop"
    ];

    bindl = [ ", code:113, exec, wpctl set-volume @DEFAULT_SOURCE@ 100%" ];

    bindrl = [ ", code:113, exec, wpctl set-volume @DEFAULT_SOURCE@ 0%" ];

    binde = [
      ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
      ", code:224, exec, ${pkgs.brightnessctl}/bin/brightnessctl set +5%"
      ", code:225, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
    ];

    bindm =
      [ "$mainMod, mouse:272, movewindow" "$mainMod, mouse:273, resizewindow" ];
  };
}
