{ options, config, pkgs, lib, inputs, ... }:
with lib;
with lib.custom;
let
  cfg = config.apps.kitty;
  inherit (inputs.nix-colors.colorschemes.${
      builtins.toString config.desktop.colorscheme
    })
    palette;
in {
  options.apps.kitty = with types; {
    enable = mkBoolOpt false "Enable or disable the kitty terminal.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kitty ];

    home.configFile."kitty/kitty.conf".text = ''
      startup_session launch.conf


      font_family JetBrains Mono Nerd Font
      font_size 12
      window_padding_width 5

      foreground #${palette.base05}
      background #${palette.base00}

      # Normal colors
      color0 #${palette.base03}
      color1 #${palette.base08}
      color2 #${palette.base0B}
      color3 #${palette.base0A}
      color4 #${palette.base0D}
      color5 #${palette.base0F}
      color6 #${palette.base0C}
      color7 #${palette.base05}

      # Bright colors
      color8 #${palette.base04}
      color9 #${palette.base08}
      color10 #${palette.base0B}
      color11 #${palette.base0A}
      color12 #${palette.base0D}
      color13 #${palette.base0F}
      color14 #${palette.base0C}
      color15 #${palette.base05}
    '';

    home.configFile."kitty/launch.conf".text = ''
      launch zellij -l welcome
    '';
  };
}
