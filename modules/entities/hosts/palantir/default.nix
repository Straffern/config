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
      den.aspects.platform.boot-grub
      den.aspects.services.robomp-funnel
    ];

    provides.alex = {
      includes = [
        den.aspects.profiles.development-core
        den.aspects.cli.omp
      ];
      homeManager = {lib, ...}: {
        programs.zsh.sessionVariables.PATH = "$HOME/.local/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
        # Palantir's own GitHub key: ~/.ssh/github is generated here, passphrase-free and never leaves
        # the host, so T3 and other agents reach GitHub and sign while Alex is disconnected. Git
        # signs with the private key file because no agent holds it.
        home.file.".ssh/github.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IwHs/v4N9J/usNHCA49toWB+GSWD+E0W3SxGbvETQ alex@flensborg.dev github palantir\n";
        programs.git.settings.user.signingkey = lib.mkForce "~/.ssh/github";
        # Keep the key out of whichever agent sonic forwards.
        programs.ssh.settings."github.com".AddKeysToAgent = lib.mkForce "no";
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
      ];
      # Moved from the shared podman aspect so only palantir keeps rootful docker socket access.
      virtualisation.podman.dockerSocket.enable = true;
      users.users.alex.extraGroups = ["podman"];
      services.journald.extraConfig = "SystemMaxUse=500M";
      # 7.6 GiB of RAM: agent dev servers and nix builds otherwise stall T3 threads or hit the OOM killer.
      # zram (priority 5) takes swap first; the disk swapfile (default priority -2) catches overflow.
      zramSwap.enable = true;
      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 8192;
        }
      ];
      system.stateVersion = "26.05";
      services.robomp = {
        # Off until the GitHub App exists: set app.*, add robomp_app_private_key to the sopsFile.
        enable = false;
        repositories = ["heretask/platform"];
        secrets.sopsFile = ../../../../secrets/hosts/palantir-robomp.yaml;
        # RomM owns 127.0.0.1:8080.
        listen.port = 8090;
        bot = {
          login = "heretask-robomp";
          maintainers = ["Straffern"];
        };
        settings = {
          ROBOMP_MAX_CONCURRENCY = 2;
          ROBOMP_PR_REVIEW_ENABLED = false;
          ROBOMP_QUESTION_AUTOCLOSE_ENABLED = false;
        };
      };
    };
  };
}
