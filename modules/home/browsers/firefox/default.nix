{ lib, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.browsers.firefox;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.browsers.firefox = {
    enable = mkEnableOption "Firefox";
  };

  config = mkIf cfg.enable {
    programs.librewolf = enabled;

    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [ ".librewolf" ".cache/librewolf" ];
    };
  };
}
