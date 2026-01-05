{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.waybar;

  # Get hyprwhspr tray script path if hyprwhspr is enabled
  hyprwhsprEnabled = config.${namespace}.programs.hyprwhspr.enable or false;
  customPyWhisperCpp = pkgs.${namespace}.pywhispercpp.override {
    gpuSupport = config.${namespace}.programs.hyprwhspr.gpuSupport or "vulkan";
  };
  customHyprwhspr =
    pkgs.${namespace}.hyprwhspr.override { pywhispercpp = customPyWhisperCpp; };
  trayScript =
    "${customHyprwhspr}/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh";
in {
  options.${namespace}.desktops.addons.waybar = {
    enable = mkEnableOption "Waybar";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = [{
        layer = "top";
        position = "top";
        margin = "0 0 0 0";
        modules-left = [ "hyprland/workspaces" "tray" ];
        # NOTE: If you see "Unable to replace properties on 0: Error getting properties for ID" 
        # in waybar logs, it is a benign protocol mismatch from tray applets (like blueman).
        # It does not affect functionality.
        modules-center = (lib.optional hyprwhsprEnabled "custom/hyprwhspr")
          ++ [ "custom/notification" "clock" "idle_inhibitor" ];
        modules-right = [
          "power-profiles-daemon"
          "backlight"
          "battery"
          "pulseaudio"
          "network"
        ];
        "hyprland/workspaces" = {
          format = "{icon}";
          sort-by-number = true;
          active-only = false;
          format-icons = {
            "1" = " 󰲌 ";
            "2" = "  ";
            "3" = " 󰎞 ";
            "4" = "  ";
            "5" = "  ";
            "6" = " 󰺵 ";
            "7" = "  ";
            urgent = "  ";
            focused = "  ";
            default = "  ";
          };
          on-click = "activate";
        };
        clock = {
          format = "󰃰 {:%a, %d %b, %I:%M %p}";
          interval = 1;
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            locale = "da_DK.UTF-8";
            mode = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "on-click-right" = "mode";
            format = {
              months = "<span color='#cba6f7'><b>{}</b></span>";
              days = "<span color='#b4befe'><b>{}</b></span>";
              weeks = "<span color='#89dceb'><b>W{}</b></span>";
              weekdays = "<span color='#f2cdcd'><b>{}</b></span>";
              today = "<span color='#f38ba8'><b><u>{}</u></b></span>";
            };
          };
        };
        "custom/notification" = {
          tooltip = false;
          format = "{} {icon}";
          "format-icons" = {
            notification = "󱅫";
            none = "󰂚";
            "dnd-notification" = " ";
            "dnd-none" = "󰂛";
            "inhibited-notification" = " ";
            "inhibited-none" = "󰂚";
            "dnd-inhibited-notification" = " ";
            "dnd-inhibited-none" = " ";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          exec = "swaync-client -swb";
          "on-click" = "sleep 0.1 && swaync-client -t -sw";
          "on-click-right" = "sleep 0.1 && swaync-client -d -sw";
          escape = true;
        };
        "custom/hyprwhspr" = lib.mkIf hyprwhsprEnabled {
          tooltip = true;
          format = "{}";
          "return-type" = "json";
          interval = 1;
          "exec-on-event" = true;
          exec = "${trayScript} status";
          "on-click" = "${trayScript} record";
          "on-click-right" = "${trayScript} restart";
        };
        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "  ";
            deactivated = "  ";
          };
        };
        backlight = { format = " {percent}%"; };
        battery = {
          states = {
            good = 80;
            warning = 50;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-alt = "{time}";
          format-charging = "  {capacity}%";
          format-icons = [ "󰁻 " "󰁽 " "󰁿 " "󰂁 " "󰂂 " ];
        };
        network = {
          interval = 1;
          format-wifi = "  {essid}";
          format-ethernet = " 󰈀 ";
          format-disconnected = " 󱚵  ";
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            {signalStrength}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}
          '';
        };
        pulseaudio = {
          scroll-step = 2;
          format = "{icon} {volume}%";
          format-bluetooth = " {icon} {volume}%";
          format-muted = "  ";
          format-icons = {
            headphone = "  ";
            headset = "  ";
            default = [ "  " "  " ];
          };
        };
        tray = {
          icon-size = 16;
          spacing = 8;
        };
        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = ''
            Power profile: {profile}
            Driver: {driver}'';
          tooltip = true;
          format-icons = {
            default = "󰾅";
            performance = "󰓅";
            balanced = "󰾅";
            power-saver = "󰌪";
          };
        };
      }];

      style = builtins.readFile ./styles.css;
    };
  };
}
