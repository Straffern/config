{
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.${namespace}.styles.fonts;
in {
  options.${namespace}.styles.fonts = {
    enable = mkEnableOption "System font infrastructure";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;
      fontconfig = {
        enable = true;
        localConf = ''
          <alias>
            <family>monospace</family>
            <prefer><family>Symbols Nerd Font</family></prefer>
          </alias>
        '';
      };
    };
  };
}
