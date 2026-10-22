{den, ...}: {
  den.aspects.profiles.server = {
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
    ];
  };
}
