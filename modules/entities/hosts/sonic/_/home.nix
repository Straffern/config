_: {
  den.aspects._sonic-home.homeManager = {config, ...}: {
    programs.zsh.sessionVariables.PATH = "$XDG_BIN_HOME:$HOME/go/bin:$HOME/.npm-global/bin:$PATH:$XDG_CACHE_HOME/.bun/bin";
    programs.ssh.includes = [config.sops.secrets.ssh_config.path];
    sops.secrets.ssh_config.sopsFile = ../../../../../secrets/hosts/sonic.yaml;
  };
}
