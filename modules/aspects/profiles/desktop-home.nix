{den, ...}: {
  den.aspects.profiles.desktop-home = {
    includes = [
      den.aspects.profiles.development
      den.aspects.cli.kitty
      den.aspects.development.state
      den.aspects.apps.brave
      den.aspects.apps.helium
      den.aspects.apps.slack
      den.aspects.apps.blender
      den.aspects.apps.kdeconnect
      den.aspects.apps.desktop-utilities
      den.aspects.desktop.addons.xdg
      den.aspects.desktop.kitty
    ];
  };
}
