{den, ...}: {
  den.aspects.profiles.kubernetes = {
    includes = [
      den.aspects.profiles.server
      den.aspects.services.k3s
    ];
  };
}
