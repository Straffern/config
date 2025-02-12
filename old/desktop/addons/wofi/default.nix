{ options, config, lib, pkgs, inputs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.addons.wofi;
  inherit (inputs.nix-colors.colorschemes.${
      builtins.toString config.${namespace}.desktop.colorscheme
    })
    palette;
in {
  options.${namespace}.desktop.addons.wofi = with types; {
    enable = mkBoolOpt false "Enable or disable the wofi run launcher.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wofi ];

    home.configFile."wofi/config".source = ./config;
    home.configFile."wofi/style.css".text = ''
      window {
          margin: 5px;
          border: 5px solid #181926;
          background-color: #${palette.base00};
          border-radius: 15px;
          font-family: "JetBrainsMono";
          font-size: 14px;
        }

        #input {
          all: unset;
          min-height: 36px;
          padding: 4px 10px;
          margin: 4px;
          border: none;
          color: #${palette.base05};
          font-weight: bold;
          background-color: #${palette.base01};
          outline: none;
          border-radius: 15px;
          margin: 10px;
          margin-bottom: 2px;
        }

        #inner-box {
          margin: 4px;
          padding: 10px;
          font-weight: bold;
          border-radius: 15px;
        }

        #outer-box {
          margin: 0px;
          padding: 3px;
          border: none;
          border-radius: 15px;
          border: 5px solid #${palette.base01};
        }

        #scroll {
          margin-top: 5px;
          border: none;
          border-radius: 15px;
          margin-bottom: 5px;
        }

        #text:selected {
          color: #${palette.base01};
          margin: 0px 0px;
          border: none;
          border-radius: 15px;
        }

        #entry {
          margin: 0px 0px;
          border: none;
          border-radius: 15px;
          background-color: transparent;
        }

        #entry:selected {
          margin: 0px 0px;
          border: none;
          border-radius: 15px;
          background: #${palette.base0D};
          background-size: 400% 400%;
        }
    '';
  };
}
