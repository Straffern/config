{
  den,
  inputs,
  ...
}: {
  imports = [./_/frostmourne/users.nix];

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
        ./_/frostmourne/disko.nix
        ./_/frostmourne/hardware-configuration.nix
        ./_/frostmourne/nixos.nix
      ];
      networking.hostName = "frostmourne";
      system.stateVersion = "26.05";
    };
  };
}
