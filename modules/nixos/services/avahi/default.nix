{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.${namespace}.avahi;
in {
  options.services.${namespace}.avahi = { enable = mkEnableOption "Avahi"; };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };
  };
}
