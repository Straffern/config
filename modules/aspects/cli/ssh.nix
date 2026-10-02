{den, ...}: {
  den.aspects.cli.ssh.homeManager = {
    config,
    lib,
    host,
    ...
  }:
    lib.mkMerge [
      {
        services.ssh-agent = {
          enable = true;
          defaultMaximumIdentityLifetime = 8 * 60 * 60;
        };
        # HM exports the socket only to shells; graphical apps read the systemd user environment.
        systemd.user.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/${config.services.ssh-agent.socket}";
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*" = {
            AddKeysToAgent = "yes";
            Compression = "yes";
            ControlMaster = "auto";
            ControlPath = "~/.ssh/cm-%r@%h:%p";
            ControlPersist = "10m";
            IdentityFile = "~/.ssh/id_ed25519";
            IPQoS = "lowdelay throughput";
            SetEnv.TERM = "xterm";
            TCPKeepAlive = "no";
          };
        };
        programs.zsh.initContent = lib.mkAfter ''
          ssh-unlock() {
            local key="$HOME/.ssh/id_ed25519"
            ssh-add -T "$key.pub" >/dev/null 2>&1 || ssh-add -t 8h "$key"
          }
        '';
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".ssh"];
      })
    ];
}
