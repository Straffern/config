{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.suites.common;
in {
  options.${namespace}.suites.common.enable = mkEnableOption "Common Suite";

  config = mkIf cfg.enable {
    ${namespace}.hardware = { networking.enable = true; };

    services = { ssh.enable = true; };

    ${namespace}.security = {
      sops.enable = true;
      # yubikey.enable = true;
    };

    ${namespace}.system = {
      nix.enable = true;
      boot.enable = true;
      locale.enable = true;
    };
    ${namespace}.styles.stylix.enable = true;
  };
}
