{den, ...}: {
  den.aspects.network.vpn = {
    includes = [den.aspects.services.tailscale];

    nixos.networking.wireguard.enable = true;
  };
}
