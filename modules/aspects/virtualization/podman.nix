{den, ...}: {
  den.aspects.virtualization.podman.nixos = {
    host,
    lib,
    ...
  }: {
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    environment.persistence."/persist".directories =
      lib.mkIf (host.hasAspect den.aspects.platform.impermanence)
      ["/var/lib/containers"];
  };
}
