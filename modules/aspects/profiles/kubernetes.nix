{den, ...}: {
  den.aspects.profiles.kubernetes = {
    includes = [
      den.aspects.profiles.server
      den.aspects.services.k3s
    ];
    nixos = {
      config,
      lib,
      ...
    }: {
      assertions = [
        {
          assertion = config.services.k3s.role != "agent" || config.services.k3s.serverAddr != null;
          message = "serverAddr must be set when role is 'agent'";
        }
      ];
      services.k3s.enable = true;
      networking.firewall.allowedUDPPorts = [
        53
        8472
      ];
      networking.firewall.allowedTCPPorts = [
        22
        53
        6443
        6444
        9000
        445
        139
      ];
    };
  };
}
