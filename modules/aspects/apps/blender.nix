{den, ...}: {
  den.aspects.apps.blender.homeManager = {
    lib,
    host,
    ...
  }:
    lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/blender"];
    };
}
