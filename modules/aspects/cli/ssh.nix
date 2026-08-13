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
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          matchBlocks."*" = {
            addKeysToAgent = "yes";
            compression = true;
            controlMaster = "auto";
            controlPath = "~/.ssh/cm-%r@%h:%p";
            controlPersist = "10m";
            extraOptions = {
              TCPKeepAlive = "no";
              IPQoS = "lowdelay throughput";
            };
            setEnv = {
              TERM = "xterm";
            };
            identityFile = "~/.ssh/id_ed25519";
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
