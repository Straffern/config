{
  den,
  inputs,
  ...
}: {
  den.hosts.x86_64-linux.palantir.users.alex = {};

  den.hosts.x86_64-linux.palantir = {
    deployment = {
      enable = true;
      sshUser = "alex";
      activationTimeout = 600;
      confirmTimeout = 60;
    };

    vmSmoke = {
      allowedKernelErrors = [
        "kvm_intel: VMX not supported by CPU 0"
        "kvm_intel: VMX not supported by CPU 1"
      ];
    };
  };

  den.aspects.palantir = {
    includes = [
      den.aspects.services.openssh
      den.aspects.services.tailscale
      den.aspects.security.sops
      den.aspects.security.fail2ban
      den.aspects.security.server-hardening
      den.aspects.platform.locale
      den.aspects.platform.nix
      den.aspects.platform.headless
      den.aspects.platform.server-runtime
      den.aspects.network.server
      den.aspects.cli.zsh
      den.aspects.services.tern-remote
      den.aspects.virtualization.podman
      den.aspects.platform.nix-ld
      den.aspects.platform.nh
      den.aspects.platform.boot
    ];

    provides.alex = {
      includes = [
        den.aspects.profiles.development-core
        den.aspects.cli.omp
      ];
      homeManager = {lib, ...}: {
        programs.zsh.sessionVariables.PATH = "$HOME/.local/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
        programs.git = {
          signing = {
            key = null;
            signByDefault = lib.mkForce false;
          };
          settings.commit.gpgsign = lib.mkForce false;
        };
      };
    };

    nixos = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_/disko.nix
        ./_/hardware-configuration.nix
        ./_/nixos.nix
      ];
      networking.useNetworkd = true;
      services.journald.extraConfig = "SystemMaxUse=500M";
      system.stateVersion = "26.05";
    };
  };
}
