{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.openssh;
in {
  options.${namespace}.services.openssh = {enable = mkEnableOption "SSH";};

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [22];

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        StreamLocalBindUnlink = "yes";
        KbdInteractiveAuthentication = false;
        GatewayPorts = "clientspecified";
      };
    };
  };
}
