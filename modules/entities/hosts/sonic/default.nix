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
        {
          reason = "The VM deliberately has no private Home Manager SOPS identity";
          module = {lib, ...}: {
            home-manager.users.alex.systemd.user.services.sops-nix.Unit.ConditionPathExists =
              lib.mkForce "/run/vm-smoke-sops-identity";
          };
        }
        {
          reason = "Exercise activation and greeter against state left by the previous generation";
          module = {
            systemd.tmpfiles.rules = [
              "d /home/alex 0755 alex users -"
              "d /home/alex/.config 0755 alex users -"
              "d /home/alex/.config/gtk-3.0 0755 alex users -"
              "f /home/alex/.config/gtk-3.0/settings.ini 0644 alex users - legacy"
              "d /home/alex/.config/DankMaterialShell 0755 alex users -"
              "f /home/alex/.config/DankMaterialShell/settings.json.pre-home-manager 0644 alex users - {\"userSetting\":\"preserved\"}"
              "d /home/alex/.local 0755 alex users -"
              "d /home/alex/.local/state 0755 alex users -"
              "d /home/alex/.local/state/DankMaterialShell 0755 alex users -"
              "f /home/alex/.local/state/DankMaterialShell/session.json.pre-home-manager 0644 alex users - {\"wallpaperPath\":\"/home/alex/Pictures/chosen.png\"}"
              "d /var/lib/dms-greeter 0750 greeter greeter -"
              "f /var/lib/dms-greeter/wallpaper 0644 greeter greeter - wallpaper"
              "f /var/lib/dms-greeter/session.json 0644 greeter greeter - {\\\"wallpaperPath\\\":\\\"/var/lib/dms-greeter/wallpaper\\\"}"
              "f /var/lib/dms-greeter/custom-theme.json 0644 greeter greeter - {}"
              "f /var/lib/dms-greeter/settings.json 0644 greeter greeter - {\\\"customThemeFile\\\":\\\"/var/lib/dms-greeter/custom-theme.json\\\"}"
            ];
            dotfiles.vmSmoke.descriptors = [
              {
                name = "home-manager-state-migration";
                description = "Home Manager adopts files from the previous generation";
                phase = "boot";
                script = ''
                  machine.wait_for_unit("home-manager-alex.service")
                  machine.succeed("grep -Fx legacy /home/alex/.config/gtk-3.0/settings.ini.pre-home-manager")
                  machine.succeed("test -f /home/alex/.config/DankMaterialShell/settings.json")
                  machine.succeed("test ! -L /home/alex/.config/DankMaterialShell/settings.json")
                  machine.succeed("runuser -u alex -- test -w /home/alex/.config/DankMaterialShell/settings.json")
                  machine.succeed("grep -F '\"userSetting\": \"preserved\"' /home/alex/.config/DankMaterialShell/settings.json")
                  machine.succeed("grep -F '\"runDmsMatugenTemplates\": true' /home/alex/.config/DankMaterialShell/settings.json")
                  machine.succeed("grep -F '\"matugenTemplateNeovim\": true' /home/alex/.config/DankMaterialShell/settings.json")
                  machine.succeed("test ! -e /home/alex/.config/DankMaterialShell/settings.json.pre-home-manager")
                  machine.succeed("test -f /home/alex/.local/state/DankMaterialShell/session.json")
                  machine.succeed("test ! -L /home/alex/.local/state/DankMaterialShell/session.json")
                  machine.succeed("runuser -u alex -- test -w /home/alex/.local/state/DankMaterialShell/session.json")
                  machine.succeed("grep -F '\"wallpaperPath\":\"/home/alex/Pictures/chosen.png\"' /home/alex/.local/state/DankMaterialShell/session.json")
                  machine.succeed("test ! -e /home/alex/.local/state/DankMaterialShell/session.json.pre-home-manager")
                '';
              }
            ];
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
      den.aspects.platform.boot
      den.aspects.hardware.amd-debug-tools
    ];
    provides.alex = {
      includes = [
        den.aspects.hardware.amd-monitoring
        den.aspects.cli.alacritty
        den.aspects.cli.lobster
        den.aspects.cli.pi
        den.aspects.cli.omp
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
        xdg.configFile = {
          "gtk-3.0/gtk.css".force = true;
          "gtk-4.0/gtk.css".force = true;
        };
        programs.ssh.includes = [config.sops.secrets.ssh_config.path];
        sops.secrets.ssh_config.sopsFile = ../../../../secrets/hosts/sonic.yaml;
      };
    };

    nixos = {...}: {
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
