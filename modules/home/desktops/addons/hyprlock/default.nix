{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.hyprlock;

  # foreground = "rgba(216, 222, 233, 0.70)";

  foreground = "rgba(${config.lib.stylix.colors.base05})";
  font = config.stylix.fonts.serif.name;
in {
  options.${namespace}.desktops.addons.hyprlock = {
    enable = mkEnableOption "Hyprlock";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
        };
        # BACKGROUND
        background = {
          monitor = "";
          # path = imageStr;
          blur_passes = 0;
          contrast = 0.8916;
          brightness = 0.7172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        };

        label = [
          {
            # Day-Month-Date
            monitor = "";
            text = ''cmd[update:1000] echo -e "$(date +"%A, %B %d")"'';
            color = foreground;
            font_size = 28;
            font_family = font + " Bold";
            position = "0, 490";
            halign = "center";
            valign = "center";
          }
          # Time
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"'';
            color = foreground;
            font_size = 160;
            font_family = "steelfish outline regular";
            position = "0, 370";
            halign = "center";
            valign = "center";
          }
          # USER
          {
            monitor = "";
            text = "    $USER";
            color = foreground;
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            font_size = 18;
            font_family = font + " Bold";
            position = "0, -180";
            halign = "center";
            valign = "center";
          }
        ];

        # INPUT FIELD
        input-field = lib.mkForce {
          monitor = "";
          size = "300, 60";
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          fade_on_empty = false;
          font_family = font + " Bold";
          placeholder_text = "<i>🔒 Enter Password</i>";
          hide_input = false;
          position = "0, -250";
          halign = "center";
          valign = "center";
        };

        # general = {
        #   disable_loading_bar = true;
        #   hide_cursor = true;
        # };
        #
        # label = [
        #   {
        #     text = ''cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"'';
        #     font_size = 25;
        #     position = {
        #       x = -30;
        #       y = -150;
        #     };
        #     halign = "right";
        #     valign = "top";
        #   }
        #   {
        #     text = ''cmd[update:30000] echo "$(date +"%R")"'';
        #     font_size = 90;
        #     position = {
        #       x = -30;
        #       y = 0;
        #     };
        #     halign = "right";
        #     valign = "top";
        #   }
        # ];
      };
    };
  };
}
