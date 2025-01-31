{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.suites.common;
in {
  options.${namespace}.suites.common.enable = mkEnableOption "Common Suite";

  config = mkIf cfg.enable {
    hardware = { networking.enable = true; };

    services = { ssh.enable = true; };

    security = {
      sops.enable = true;
      # yubikey.enable = true;
    };

    system = {
      nix.enable = true;
      boot.enable = true;
      locale.enable = true;
    };
    styles.stylix.enable = true;
  };
}
