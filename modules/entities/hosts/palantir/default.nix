{
  den,
  inputs,
  ...
}: {
  imports = [./_/home.nix];

  den.hosts.x86_64-linux.palantir.users.alex = {};

  denful.deployment.nodes.palantir = {
    enable = true;
    hostname = "palantir";
    sshUser = "alex";
    activationTimeout = 600;
    confirmTimeout = 60;
  };

  den.aspects.palantir = {
    includes = [
      den.aspects.profiles.server
      den.aspects.services.hermes
      den.aspects.services.hindsight
      den.aspects.virtualization.podman
      den.aspects.platform.nix-ld
      den.aspects.platform.boot
    ];

    provides.alex.includes = [
      den.aspects.profiles.development
      den.aspects.cli.opencode
      den.aspects.apps.clipy
      den.aspects._palantir-home
    ];

    nixos = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_/disko.nix
        ./_/hardware-configuration.nix
        ./_/nixos.nix
      ];
      services.hermes.browser.apiKeySecret = "browser_use_api_key";
      system.stateVersion = "26.05";
    };
  };
}
