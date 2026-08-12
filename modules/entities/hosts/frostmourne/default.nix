{
  den,
  inputs,
  ...
}: {
  imports = [./_/users.nix];

  den.hosts.x86_64-linux.frostmourne = {};

  denful.deployment.nodes.frostmourne = {
    enable = true;
    hostname = "frostmourne";
    sshUser = "alex";
  };

  den.aspects.frostmourne = {
    includes = [
      den.aspects.profiles.kubernetes
      den.aspects.platform.boot
      den.aspects._frostmourne-users
    ];

    nixos = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_/disko.nix
        ./_/hardware-configuration.nix
        ./_/nixos.nix
      ];
      networking.hostName = "frostmourne";
      system.stateVersion = "26.05";
    };
  };
}
