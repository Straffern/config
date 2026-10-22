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
      den.aspects.services.tern-remote
      den.aspects.services.romm
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
        # No private key lives here: GitHub login and commit signing use the GitHub key in sonic's
        # forwarded agent. Its public half lets ssh and git pick that key out of the agent.
        home.file.".ssh/github.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH15qRZdMTlZNShbLzFjySltD6Lr17aMGHeiQvsu1NH/ alex@flensborg.dev github sonic\n";
        # A forwarded socket dies with its connection, so everything here uses agent.sock, which sshd
        # points at the newest terminal login's agent: tmux panes and agents outlive the login they
        # started under. Logins without a terminal, like deploys, leave the link alone.
        services.ssh-agent.enable = lib.mkForce false;
        home.file.".ssh/rc".text = ''
          if [ -n "$SSH_TTY" ] && [ -S "$SSH_AUTH_SOCK" ]; then ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"; fi
        '';
        programs.zsh.profileExtra = ''export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"'';
        systemd.user.sessionVariables.SSH_AUTH_SOCK = lib.mkForce "$HOME/.ssh/agent.sock";
      };
    };

    nixos = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_/disko.nix
        ./_/hardware-configuration.nix
        ./_/nixos.nix
      ];
      # Moved from the shared podman aspect so only palantir keeps rootful docker socket access.
      virtualisation.podman.dockerSocket.enable = true;
      users.users.alex.extraGroups = ["podman"];
      services.journald.extraConfig = "SystemMaxUse=500M";
      system.stateVersion = "26.05";
    };
  };
}
