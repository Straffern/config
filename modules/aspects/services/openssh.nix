{den, ...}: {
  den.aspects.services.openssh.nixos = {
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
