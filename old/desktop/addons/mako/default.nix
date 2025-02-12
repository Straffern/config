{ options, config, lib, pkgs, inputs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.addons.mako;
  inherit (inputs.nix-colors.colorschemes.${
      builtins.toString config.desktop.colorscheme
    })
    palette;
in {
  options.${namespace}.desktop.addons.mako = with types; {
    enable = mkBoolOpt false "Enable or disable mako";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mako libnotify ];

    home.configFile."mako/config" = {
      text = ''
        # GLOBAL CONFIGURATION OPTIONS
        max-history=100
        sort=-time

        # STYLE OPTIONS
        font=JetBrains Mono 10
        width=300
        height=100
        margin=10
        padding=15
        border-size=2
        border-radius=0
        icons=1
        max-icon-size=48
        icon-location=left
        markup=1
        actions=1
        history=1
        text-alignment=left
        default-timeout=5000
        ignore-timeout=0
        max-visible=5
        layer=overlay
        anchor=top-right

        background-color=#${palette.base00}
        text-color=#${palette.base05}
        border-color=#${palette.base0D}
        progress-color=over #${palette.base02}


        [urgency=low]
        border-color=#${palette.base0D}
        default-timeout=2000

        [urgency=normal]
        border-color=#${palette.base0D}
        default-timeout=5000

        [urgency=high]
        border-color=#${palette.base09}
        text-color=#${palette.base05}
        default-timeout=0

      '';
      onChange = ''
        ${pkgs.busybox}/bin/pkill -SIGUSR2 mako
      '';
    };
  };
}
