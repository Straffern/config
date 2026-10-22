{den, ...}: {
  den.aspects.profiles.kubernetes = {
    includes = [
      den.aspects.profiles.server
      den.aspects.services.k3s
      den.aspects.storage.remote-clients
    ];
  };
}
