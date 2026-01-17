{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktops.hyprland;
  laptop_lid_switch = pkgs.writeShellScriptBin "laptop_lid_switch" ''
    #!/usr/bin/env bash

    if grep open /proc/acpi/button/lid/LID/state || grep open /proc/acpi/button/lid/LID[0-9]/state ; then
    		hyprctl keyword monitor "eDP-1, preffered, 0x0, 1.5"
    else
    		if [[ `hyprctl monitors | grep "Monitor" | wc -l` != 1 ]]; then
    				hyprctl keyword monitor "eDP-1, disable"
    		else
    				systemctl suspend
    		fi
    fi
  '';

  resize = pkgs.writeShellScriptBin "resize" ''
    #!/usr/bin/env bash

    # Initially inspired by https://github.com/exoess

    # Getting some information about the current window
    # windowinfo=$(hyprctl activewindow) removes the newlines and won't work with grep
    hyprctl activewindow > /tmp/windowinfo
    windowinfo=/tmp/windowinfo

    # Run slurp to get position and size
    if ! slurp=$(slurp); then
    		exit
    fi

    # Parse the output
    pos_x=$(echo $slurp | cut -d " " -f 1 | cut -d , -f 1)
    pos_y=$(echo $slurp | cut -d " " -f 1 | cut -d , -f 2)
    size_x=$(echo $slurp | cut -d " " -f 2 | cut -d x -f 1)
    size_y=$(echo $slurp | cut -d " " -f 2 | cut -d x -f 2)

    # Keep the aspect ratio intact for PiP
    if grep "title: Picture-in-Picture" $windowinfo; then
    		old_size=$(grep "size: " $windowinfo | cut -d " " -f 2)
    		old_size_x=$(echo $old_size | cut -d , -f 1)
    		old_size_y=$(echo $old_size | cut -d , -f 2)

    		size_x=$(((old_size_x * size_y + old_size_y / 2) / old_size_y))
    		echo $old_size_x $old_size_y $size_x $size_y
    fi

    # Resize and move the (now) floating window
    grep "fullscreen: 1" $windowinfo && hyprctl dispatch fullscreen
    grep "floating: 0" $windowinfo && hyprctl dispatch togglefloating
    hyprctl dispatch moveactive exact $pos_x $pos_y
    hyprctl dispatch resizeactive exact $size_x $size_y
  '';

in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = let

      browser = "uwsm app -- brave --new-window";
      webapp = url: "${browser} --app=${url}";

      rofi_prompt = prompt_label: destination: append:
        "sh -c 'query=$(${
          config.${namespace}.desktops.addons.rofi.package
        }/bin/rofi -dmenu -p \"${prompt_label}\"); [ -n \"$query\" ] && ${destination}$query${append}\"'";
      webapp_prompt = "sh -c 'query=$(${
          config.${namespace}.desktops.addons.rofi.package
        }/bin/rofi -dmenu -p \"Open Link as Webapp\"); [ -n \"$query\" ] && ${browser} --app=\"$query\"'";
      hexdocs_prompt = "sh -c 'query=$(${
          config.${namespace}.desktops.addons.rofi.package
        }/bin/rofi -dmenu -p \"HexDocs Search\"); if [ -n \"$query\" ]; then read -r library search_query <<< \"$query\"; if [ -z \"$search_query\" ]; then ${
          webapp ''"https://hexdocs.pm/$library/"''
        }; else ${
          webapp ''"https://hexdocs.pm/$library/search.html?q=$search_query"''
        }; fi; fi'";

      ai_chat_selector =
        "sh -c 'selected=$(echo -e \"T3 Chat\\nClaude\\nGrok\" | ${
          config.${namespace}.desktops.addons.rofi.package
        }/bin/rofi -dmenu -i -p \"AI Chat\"); case \"$selected\" in \"T3 Chat\") ${
          webapp ''"https://t3.chat"''
        } ;; \"Claude\") ${webapp ''"https://claude.ai/new"''} ;; \"Grok\") ${
          webapp ''"https://grok.com"''
        } ;; esac'";

    in {
      bind = [
        "SUPER, Return, exec, kitty -1"
        "SUPER, B, exec, ${
          config.${namespace}.desktops.addons.rofi.package
        }/bin/rofi -show drun -run-command 'uwsm app -- {cmd}'"
        "SUPER, A, exec, ${ai_chat_selector}"
        "SUPER, W, exec, ${webapp_prompt}"
        "SUPER, D, exec, ${hexdocs_prompt}"
        "SUPER, X, exec, ${webapp ''"https://x.com/"''}"
        "SUPER_SHIFT, X, exec, ${webapp ''"https://x.com/compose/post"''}"
        "SUPER, Y, exec, ${webapp ''"https://youtube.com/"''}"
        "SUPER, O, exec, ${webapp ''"https://panel.orionoid.com/"''}"

        "SUPER, slash, togglesplit,"
        "SUPER, Q, killactive,"
        "SUPER, F, Fullscreen,0"
        "SUPER, R, exec, ${resize}/bin/resize"
        "SUPER, Space, togglefloating,"
        "SUPER, S, pin"
        "SUPER, TAB, pseudo"

        # Transparency toggle
        ''
          SUPER, T, exec, hyprctl dispatch setprop "address:$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address')" opaque toggle''

        # Group management
        "SUPER, G, lockgroups, toggle" # Lock groups
        "SUPERSHIFT, G, togglegroup" # Create/leave group
        "SUPERCONTROL, G, changegroupactive, f" # Cycle to next window in group
        "SUPER, comma, changegroupactive, b" # Previous window in group
        "SUPER, semicolon, changegroupactive, f" # Next window in group

        # Directional group merging (merge window with adjacent group)
        "SUPERCONTROL, h, movewindoworgroup, l" # Merge/move with group to left
        "SUPERCONTROL, l, movewindoworgroup, r" # Merge/move with group to right
        "SUPERCONTROL, k, movewindoworgroup, u" # Merge/move with group above
        "SUPERCONTROL, j, movewindoworgroup, d" # Merge/move with group below

        "SUPER, V, exec, ${pkgs.pyprland}/bin/pypr toggle volume"
        "SUPER_SHIFT, T, exec, ${pkgs.pyprland}/bin/pypr toggle term"
        "SUPER, M, exec, ${pkgs.blueman}/bin/blueman-manager"
        ",XF86Launch5, exec,${pkgs.hyprlock}/bin/hyprlock"
        ",XF86Launch4, exec,${pkgs.hyprlock}/bin/hyprlock"
        "SUPER,backspace, exec,${pkgs.hyprlock}/bin/hyprlock"
        "CTRL_SUPER,backspace, exec,wlogout --column-spacing 50 --row-spacing 50"
        # ",Print, exec,grimblast --notify copysave area"
        "SUPERALT,P, exec,grimblast --notify copysave area"
        # "SHIFT, Print, exec,grimblast --notify copy active"
        "SUPERSHIFT, P, exec,grimblast --notify copy active"
        # "CONTROL,Print, exec,grimblast --notify copy screen"
        # "CONTROL,Print, exec,grimblast --notify copy screen"
        "SUPERCONTROL,P, exec,grimblast --notify copy screen"
        # "SUPER,Print, exec,grimblast --notify copy window"
        "SUPER,P, exec,grimblast --notify copy area"
        # "ALT,Print, exec,grimblast --notify copy area"
        # "SUPERALT,P, exec,grimblast --notify copy area"
        # ''
        #   SUPER,bracketleft, exec,grimblast --notify --cursor copysave area ~/Pictures/$(date " + %Y-%m-%d "T"%H:%M:%S_no_watermark ").png''
        # "SUPER,bracketright, exec, grimblast --notify --cursor copy area"

        "SUPER,bracketright, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
        "SUPER,bracketleft, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"

        "SUPER,h, movefocus,l"
        "SUPER,l, movefocus,r"
        "SUPER,k, movefocus,u"
        "SUPER,j, movefocus,d"
        # "SUPERCONTROL,h, focusmonitor,l"
        # "SUPERCONTROL,l, focusmonitor,r"
        # "SUPERCONTROL,k, focusmonitor,u"
        # "SUPERCONTROL,j, focusmonitor,d"
        "SUPER,1, workspace,01"
        "SUPER,2, workspace,02"
        "SUPER,3, workspace,03"
        "SUPER,4, workspace,04"
        "SUPER,5, workspace,05"
        "SUPER,6, workspace,06"
        "SUPER,7, workspace,07"
        "SUPER,8, workspace,08"
        "SUPER,9, workspace,09"
        "SUPER,0, workspace,10"
        "SUPERSHIFT,1, movetoworkspacesilent,01"
        "SUPERSHIFT,2, movetoworkspacesilent,02"
        "SUPERSHIFT,3, movetoworkspacesilent,03"
        "SUPERSHIFT,4, movetoworkspacesilent,04"
        "SUPERSHIFT,5, movetoworkspacesilent,05"
        "SUPERSHIFT,6, movetoworkspacesilent,06"
        "SUPERSHIFT,7, movetoworkspacesilent,07"
        "SUPERSHIFT,8, movetoworkspacesilent,08"
        "SUPERSHIFT,9, movetoworkspacesilent,09"
        "SUPERSHIFT,0, movetoworkspacesilent,10"
        # "SUPERALT,h, movecurrentworkspacetomonitor,l"
        # "SUPERALT,l, movecurrentworkspacetomonitor,r"
        # "SUPERALT,k, movecurrentworkspacetomonitor,u"
        # "SUPERALT,j, movecurrentworkspacetomonitor,d"
        # "ALTCTRL,L, movewindow,r"
        # "ALTCTRL,H, movewindow,l"
        # "ALTCTRL,K, movewindow,u"
        # "ALTCTRL,J, movewindow,d"
        # Move window with mainMod_SHIFT + arrow keys
        "SUPERSHIFT,h, movewindow,l"
        "SUPERSHIFT,l, movewindow,r"
        "SUPERSHIFT,k, movewindow,u"
        "SUPERSHIFT,j, movewindow,d"
        # "SUPERSHIFT,h, swapwindow,l"
        # "SUPERSHIFT,l, swapwindow,r"
        # "SUPERSHIFT,k, swapwindow,u"
        # "SUPERSHIFT,j, swapwindow,d"
        "SUPER,u, togglespecialworkspace"
        "SUPERSHIFT,u, movetoworkspace,special"
      ];
      bindi = [
        ",XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
        ",XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
        ",XF86AudioRaiseVolume, exec, ${pkgs.pamixer}/bin/pamixer -i 5"
        ",XF86AudioLowerVolume, exec, ${pkgs.pamixer}/bin/pamixer -d 5"
        ",XF86AudioMute, exec, ${pkgs.pamixer}/bin/pamixer --toggle-mute"
        ",XF86AudioMicMute, exec, ${pkgs.pamixer}/bin/pamixer --default-source --toggle-mute"
        ",XF86AudioNext, exec,playerctl next"
        ",XF86AudioPrev, exec,playerctl previous"
        ",XF86AudioPlay, exec,playerctl play-pause"
        ",XF86AudioStop, exec,playerctl stop"
      ];
      bindl = [
        ",switch:Lid Switch, exec, ${laptop_lid_switch}/bin/laptop_lid_switch"
      ];
      binde = [
        "SUPERALT, h, resizeactive, -20 0"
        "SUPERALT, l, resizeactive, 20 0"
        "SUPERALT, k, resizeactive, 0 -20"
        "SUPERALT, j, resizeactive, 0 20"
      ];
      bindm =
        [ "SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow" ];
    };
  };
}
