{den, ...}: {
  den.aspects.network.networkmanager.nixos = {
    networking.firewall.enable = true;
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.powersave = false;
    networking.dhcpcd.enable = false;
  };
  den.aspects.network.networkmanager.user.extraGroups = ["networkmanager"];
}
