{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.terminals.foot;
in {
  options.${namespace}.cli.terminals.foot = {
    enable = mkEnableOption "Foot terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.foot = {
      enable = true;

      settings = {
        main = {
          shell = "zsh";
          pad = "15x15";
          selection-target = "clipboard";
        };

        scrollback = { lines = 10000; };
      };
    };
  };
}
