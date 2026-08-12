{den, ...}: {
  den.aspects.network.avahi.nixos = {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true; # Apple devices often prefer IPv6 for discovery
      openFirewall = true;
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
