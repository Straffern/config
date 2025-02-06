{ lib, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.browsers.firefox;
in {
  options.${namespace}.browsers.firefox = {
    enable = mkEnableOption "Firefox";
  };

  config = mkIf cfg.enable {
    programs.librewolf = enabled;
    home.persistence."/persist".users.${config.home.username}.directories =
      [ ".librewolf" ".cache/librewolf" ];
  };
}
