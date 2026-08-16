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
      den.aspects.profiles.server
      den.aspects.services.hermes-palantir-dashboard
      den.aspects.services.hindsight-tailnet
      den.aspects.styles.icons
      den.aspects.styles.stylix
      den.aspects.virtualization.podman
      den.aspects.platform.nix-ld
      den.aspects.platform.nh
      den.aspects.platform.boot
    ];

    provides.alex = {
      includes = [
        den.aspects.profiles.development
        den.aspects.cli.opencode
        den.aspects.apps.clipy
      ];
      homeManager = {
        lib,
        pkgs,
        ...
      }: {
        programs.zsh.sessionVariables.PATH = "$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
        programs.git = {
          signing = {
            key = null;
            signByDefault = lib.mkForce false;
          };
          settings.commit.gpgsign = lib.mkForce false;
        };
        stylix = {
          enable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
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
      services.hermes.browser.apiKeySecret = "browser_use_api_key";
      system.stateVersion = "26.05";
    };
  };
}
