{
  den,
  inputs,
  lib,
  ...
}: let
  vmCores = 2;
in {
  den.hosts.x86_64-linux.frostmourne.users = {
    alex.classes = ["user"];
    niko.classes = ["user"];
  };

  den.hosts.x86_64-linux.frostmourne = {
    deployment = {
      enable = true;
      sshUser = "alex";
    };

    vmSmoke = {
      cores = vmCores;
      allowedKernelErrors =
        lib.genList (
          cpu: "kvm_intel: VMX not supported by CPU ${toString cpu}"
        )
        vmCores;
    };
  };

  den.aspects.frostmourne = {
    includes = [
      den.aspects.profiles.kubernetes
      den.aspects.platform.boot
      den.aspects.platform.nix-trusted-wheel
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
