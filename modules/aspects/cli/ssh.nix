{den, ...}: {
  den.aspects.cli.ssh.homeManager = {
    config,
    lib,
    host,
    ...
  }:
    lib.mkMerge [
      {
        # No identity lifetime: the GitHub key, unlocked once, stays until logout, so forwarded hosts
        # keep GitHub for the whole session.
        services.ssh-agent.enable = true;
        # HM exports the socket only to shells; graphical apps read the systemd user environment.
        systemd.user.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/${config.services.ssh-agent.socket}";
        programs.zsh.initContent = lib.mkAfter ''
          ssh-unlock() {
            ssh-add -T ~/.ssh/github.pub >/dev/null 2>&1 || ssh-add ~/.ssh/github
          }
        '';
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            # Passphrase-protected and on sonic only. ssh-unlock or the first GitHub connection from a
            # terminal loads it into the agent once per login; agents, jj signing and forwarded hosts
            # can only use it from there. Registered on GitHub for login and commit signing.
            "github.com" = {
              AddKeysToAgent = "yes";
              ControlMaster = "auto";
              ControlPath = "~/.ssh/cm-%r@%h:%p";
              ControlPersist = "10m";
              IdentityFile = "~/.ssh/github";
            };
            # The server key asks for its passphrase on every connection: it never enters the
            # agent, and no control socket lets another local process reuse an open session.
            "* !github.com" = {
              AddKeysToAgent = "no";
              ControlMaster = "no";
              IdentityFile = "~/.ssh/id_ed25519";
            };
            "*" = {
              Compression = "yes";
              IdentitiesOnly = "yes";
              IPQoS = "lowdelay throughput";
              SetEnv.TERM = "xterm";
              TCPKeepAlive = "no";
            };
          };
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".ssh"];
      })
    ];
}
