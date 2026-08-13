{
  den,
  inputs,
  ...
}: {
  flake-file.inputs = {
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [./_/home.nix];

  den.hosts.x86_64-linux.sonic.users.alex = {};

  denful.deployment.nodes.sonic = {
    enable = true;
    hostname = "sonic";
    sshUser = "alex";
  };

  den.aspects.sonic = {
    includes = [
      den.aspects.profiles.desktop
      den.aspects.profiles.desktop-home
      den.aspects.profiles.gaming
      den.aspects.desktop.niri
      den.aspects.desktop.dms
      den.aspects.services.hindsight
      den.aspects.services.tailscale
      den.aspects.virtualization.kvm
      den.aspects.virtualization.podman
      den.aspects.hardware.hidraw
      den.aspects.hardware.v4l2loopback
      den.aspects.platform.battery
      den.aspects.platform.environment
      den.aspects.platform.impermanence
      den.aspects.platform.boot
      den.aspects.hardware.amd-debug-tools
      den.aspects.platform.zsh
    ];
    provides.alex.includes = [
      den.aspects.profiles.social
      den.aspects.profiles.video
      den.aspects.profiles.gamedev
      den.aspects.cli.alacritty
      den.aspects.cli.lobster
      den.aspects.cli.opencode
      den.aspects.cli.pi
      den.aspects.cli.omp
      den.aspects.cli.ai-shell
      den.aspects.apps.waldl
      den.aspects.apps.voxtype
      den.aspects.apps.clipy
      den.aspects.apps.nwg-displays
      den.aspects.apps.guvcview
      den.aspects._sonic-home
    ];

    nixos = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_/hardware-configuration.nix
        ./_/disko.nix
        ./_/nixos.nix
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        inputs.nixos-facter-modules.nixosModules.facter
        {config.facter.reportPath = ./_/facter.json;}
      ];
      system.stateVersion = "26.05";
    };
  };
}
