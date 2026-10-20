{den, ...}: {
  den.aspects.virtualization.podman = {
    nixos = {
      lib,
      host,
      ...
    }:
      lib.mkMerge [
        {
          virtualisation.podman = {
            enable = true;
            dockerCompat = true;
            defaultNetwork.settings.dns_enabled = true;
          };
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          environment.persistence."/persist".directories = ["/var/lib/containers"];
        })
      ];

    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        amazon-ecr-credential-helper
        arion
        lazydocker
        podman
        podman-compose
        podman-tui
      ];
    };
  };
}
