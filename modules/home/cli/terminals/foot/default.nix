{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionalAttrs;
  cfg = config.${namespace}.cli.terminals.foot;
  dmsEnabled = config.programs.dank-material-shell.enable;
in {
  options.${namespace}.cli.terminals.foot = {
    enable = mkEnableOption "Foot terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.foot = {
      enable = true;

      settings = {
        main =
          {
            shell = "zsh";
            pad = "15x15";
            selection-target = "clipboard";
          }
          // optionalAttrs dmsEnabled {
            include = "${config.xdg.configHome}/foot/dank-colors.ini";
          };

        scrollback = {lines = 10000;};
      };
    };
  };
}
