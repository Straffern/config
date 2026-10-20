{den, ...}: {
  den.aspects.profiles.desktop = {
    includes = [
      den.aspects.profiles.common
      den.aspects.styles.fonts
      den.aspects.styles.icons
      den.aspects.desktop.base
      den.aspects.desktop.nautilus
      den.aspects.hardware.audio
      den.aspects.hardware.bluetooth
      den.aspects.network.avahi
      den.aspects.platform.nh
      den.aspects.platform.nix-ld
      den.aspects.platform.boot-plymouth
      den.aspects.desktop.input-tools
      den.aspects.desktop.wayland-session
      den.aspects.desktop.media-controls
      den.aspects.cli.kitty
      den.aspects.cli.foot
      den.aspects.desktop.addons.xdg
      den.aspects.desktop.addons.kanshi
    ];
  };
}
