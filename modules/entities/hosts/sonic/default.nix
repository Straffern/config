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

  den.hosts.x86_64-linux.sonic.users.alex = {};

  den.hosts.x86_64-linux.sonic = {
    deployment = {
      enable = true;
      sshUser = "alex";
    };

    vmSmoke = {
      waitForUnit = "graphical.target";
      loginUser = "alex";
      sessionCommand = "niri-session";
      memorySize = 4096;
      cores = 4;
      diskSize = 16384;
      graphics = true;
      overrides = [
        {
          reason = "The VM deliberately has no private Home Manager SOPS identity";
          module = {lib, ...}: {
            home-manager.users.alex.systemd.user.services.sops-nix.Unit.ConditionPathExists =
              lib.mkForce "/run/vm-smoke-sops-identity";
          };
        }
      ];
    };
  };

  den.aspects.sonic = {
    includes = [
      den.aspects.profiles.desktop
      den.aspects.styles.stylix
      den.aspects.desktop.addons.kanshi
      den.aspects.gaming.niri-session
      den.aspects.gaming.amd-graphics
      den.aspects.profiles.social
      den.aspects.profiles.photos
      den.aspects.cli.opencode
      den.aspects.desktop.dms
      den.aspects.services.hindsight
      den.aspects.services.tailscale
      den.aspects.network.wireguard
      den.aspects.virtualization.kvm
      den.aspects.hardware.hidraw
      den.aspects.hardware.v4l2loopback
      den.aspects.platform.battery
      den.aspects.platform.environment
      den.aspects.platform.impermanence
      den.aspects.platform.boot
      den.aspects.hardware.amd-debug-tools
    ];
    provides.alex = {
      includes = [
        den.aspects.hardware.amd-monitoring
        den.aspects.profiles.video
        den.aspects.profiles.gamedev
        den.aspects.cli.alacritty
        den.aspects.cli.lobster
        den.aspects.cli.pi
        den.aspects.cli.omp
        den.aspects.cli.ai-shell
        den.aspects.apps.waldl
        den.aspects.apps.voxtype
        den.aspects.apps.clipy
        den.aspects.apps.nwg-displays
        den.aspects.apps.guvcview
      ];
      homeManager = {config, ...}: {
        programs.zsh.sessionVariables.PATH = "$XDG_BIN_HOME:$HOME/go/bin:$HOME/.npm-global/bin:$PATH:$XDG_CACHE_HOME/.bun/bin";
        programs.ssh.includes = [config.sops.secrets.ssh_config.path];
        sops.secrets.ssh_config.sopsFile = ../../../../secrets/hosts/sonic.yaml;
      };
    };

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
