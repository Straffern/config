{den, ...}: {
  den.aspects.apps.blender.homeManager = {
    host,
    lib,
    ...
  }:
    lib.mkIf (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/blender"];
    };
}
