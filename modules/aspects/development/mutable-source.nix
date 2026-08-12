{den, ...}: {
  den.aspects.development.mutable-source.homeManager = {lib, ...}: {
    options.mutableSources.active = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
    };
  };
}
