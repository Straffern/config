{
  den,
  inputs,
  ...
}: {
  den.hosts.x86_64-linux.frostmourne.users = {
    alex.classes = ["user"];
    niko.classes = ["user"];
  };

  den.hosts.x86_64-linux.frostmourne.deployment = {
    enable = true;
    sshUser = "alex";
  };

  den.aspects.frostmourne = {
    includes = [
      den.aspects.profiles.kubernetes
      den.aspects.platform.boot
    ];

    nixos = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_/disko.nix
        ./_/hardware-configuration.nix
        ./_/nixos.nix
      ];
      system.stateVersion = "26.05";
    };
  };
}
