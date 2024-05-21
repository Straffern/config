{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.apps.foot;
  inherit (inputs.nix-colors.colorschemes.${builtins.toString config.desktop.colorscheme}) palette;
in {
  options.apps.foot = with types; {
    enable = mkBoolOpt false "Enable or disable the foot terminal.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.foot];

    
      # font=MesloLGS NF:size=12
    home.configFile."foot/foot.ini".text = ''
      font=JetBrains Mono Nerd Font:size=12
      pad=5x5
      [colors]
      foreground=${palette.base05}
      background=${palette.base00}
      regular0=${palette.base03}
      regular1=${palette.base08}
      regular2=${palette.base0B}
      regular3=${palette.base0A}
      regular4=${palette.base0D}
      regular5=${palette.base0F}
      regular6=${palette.base0C}
      regular7=${palette.base05}
      bright0=${palette.base04}
      bright1=${palette.base08}
      bright2=${palette.base0B}
      bright3=${palette.base0A}
      bright4=${palette.base0D}
      bright5=${palette.base0F}
      bright6=${palette.base0C}
      bright7=${palette.base05}
    '';
  };
}
