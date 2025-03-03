{ config, lib, namespace, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.ssh;
in {
  options.${namespace}.services.ssh = { enable = mkEnableOption "SSH"; };

  config = mkIf cfg.enable {
    services.openSSH = {
      enable = true;
      ports = [ 22 ];

      settings = {
        PasswordAuthentication = false;
        StreamLocalBindUnlink = "yes";
        GatewayPorts = "clientspecified";
      };
    };
  };
}
