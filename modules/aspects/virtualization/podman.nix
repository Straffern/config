{den, ...}: {
  den.aspects.virtualization.podman.nixos = {
    host,
    lib,
    ...
  }:
    {
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    }
    // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      environment.persistence."/persist".directories = ["/var/lib/containers"];
    };
}
