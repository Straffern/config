{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.kanshi;
in {
  options.${namespace}.desktops.addons.kanshi = {
    enable = mkEnableOption "Kanshi display addon";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ kanshi ];

    services.kanshi = {
      enable = true;
      package = pkgs.kanshi;
      systemdTarget = "hyprland-session.target";
      settings = [
        {
          profile.name = "undocked";
          profile.outputs = [{
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }];
        }
        {
          profile.name = "home_office_laptop_docked";
          profile.outputs = [
            {
              criteria = "Samsung Electric Company U32R59x H4ZN200523";
              position = "0,0";
              mode = "2560x1440@59.95100Hz";
            }
            {
              criteria = "eDP-1";
              status = "disable";
            }
          ];
        }
        # {
        #   profile.name = "home_office";
        #   profile.outputs = [
        #     {
        #       criteria =
        #         "GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U  (DP-5 via HDMI)";
        #       position = "3840,0";
        #       mode = "3840x2160@144Hz";
        #     }
        #     {
        #       criteria = "Dell Inc. DELL G3223Q 82X70P3 (DP-4)";
        #       position = "0,0";
        #       mode = "3840x2160@60Hz";
        #     }
        #   ];
        # }
        # {
        #   profile.name = "desktop";
        #   profile.outputs = [
        #     {
        #       criteria =
        #         "GIGA-BYTE TECHNOLOGY CO., LTD. Gigabyte M32U 21351B000087";
        #       position = "3840,0";
        #       mode = "3840x2160@144Hz";
        #     }
        #     {
        #       criteria = "Dell Inc. DELL G3223Q 82X70P3";
        #       position = "0,0";
        #       mode = "3840x2160@60Hz";
        #     }
        #   ];
        # }
      ];
    };
  };
}
