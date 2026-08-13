{den, ...}: {
  den.aspects.apps.blender.homeManager = _: {
    home.persistence."/persist".directories = [".config/blender"];
  };
}
