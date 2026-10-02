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
          reason = "The VM uses deterministic 2D virtio-gpu instead of Sonic's physical AMD GPU";
          module = _: {
            environment.sessionVariables.QT_QUICK_BACKEND = "software";
            virtualisation.qemu.options = [
              "-vga none"
              "-device virtio-gpu-pci"
            ];
          };
        }
      ];
    };
  };

  den.aspects.sonic = {
    includes = [
      den.aspects.profiles.desktop
      den.aspects.profiles.development
      den.aspects.virtualization.podman
      den.aspects.apps.kdeconnect
      den.aspects.apps.desktop-utilities
      den.aspects.gaming.niri-session
      den.aspects.gaming.amd-graphics
      den.aspects.apps.discord
      den.aspects.apps.helium
      den.aspects.cli.chrome-devtools
      den.aspects.apps.slack
      den.aspects.apps.shotwell
      # Desktop shell: select exactly one of desktop.noctalia or desktop.dms.
      den.aspects.desktop.noctalia
      # den.aspects.desktop.dms
      den.aspects.desktop.hyprland
      # den.aspects.services.hindsight
      den.aspects.services.tailscale
      den.aspects.network.wireguard
      den.aspects.virtualization.kvm
      den.aspects.hardware.hidraw
      den.aspects.hardware.printing
      den.aspects.hardware.v4l2loopback
      den.aspects.platform.battery
      den.aspects.platform.environment
      den.aspects.platform.boot
      den.aspects.hardware.amd-debug-tools
    ];
    provides.alex = {
      includes = [
        den.aspects.hardware.amd-monitoring
        den.aspects.cli.alacritty
        den.aspects.cli.lobster
        den.aspects.cli.pi
        den.aspects.cli.ji
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
      # hardware.printers = {
      #   ensurePrinters = [
      #     {
      #       name = "Canon-TS3300-series";
      #       description = "Canon TS3300 series";
      #       location = "home";
      #       deviceUri = "ipp://33A649000000.local:631/ipp/print";
      #       model = "everywhere";
      #       ppdOptions.PageSize = "A4";
      #     }
      #   ];
      #   ensureDefaultPrinter = "Canon-TS3300-series";
      # };

      home-manager = {
        backupFileExtension = "pre-home-manager";
        overwriteBackup = true;
      };
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
