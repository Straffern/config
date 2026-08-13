{den, ...}: {
  den.aspects.profiles.server = {
    includes = [
      den.aspects.profiles.common
      den.aspects.network.avahi
      den.aspects.services.tailscale
      den.aspects.security.fail2ban
      den.aspects.storage.remote-clients
      den.aspects.network.server
      den.aspects.platform.headless
      den.aspects.platform.server-runtime
      den.aspects.security.server-hardening
    ];
  };
}
