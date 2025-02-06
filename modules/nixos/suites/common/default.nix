{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.common;
in {
  options.${namespace}.suites.common.enable = mkEnableOption "Common Suite";

  config = mkIf cfg.enable {
    services = { ssh = enabled; };

    ${namespace} = {
      hardware = { networking = enabled; };
      security = { sops = enabled; };
      system = {
        nix = enabled;
        boot = enabled;
        locale = enabled;
      };
      styles.stylix = enabled;
    };

  };
}
