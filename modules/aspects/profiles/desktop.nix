{den, ...}: {
  den.aspects.profiles.desktop = {
    includes = [
      den.aspects.profiles.common
      den.aspects.profiles.development
      den.aspects.cli.kitty
      den.aspects.development.state
      den.aspects.apps.slack
      den.aspects.apps.blender
      den.aspects.apps.kdeconnect
      den.aspects.apps.spotify
      den.aspects.apps.trayscale
      den.aspects.apps.foliate
      den.aspects.apps.pavucontrol
      den.aspects.apps.pwvucontrol
      den.aspects.apps.sushi
      den.aspects.apps.gnome-disk-utility
      den.aspects.apps.totem
      den.aspects.apps.loupe
      den.aspects.apps.nautilus
      den.aspects.desktop.base
      den.aspects.desktop.kitty
      den.aspects.desktop.input-tools
      den.aspects.desktop.wayland-session
      den.aspects.desktop.media-controls
      den.aspects.desktop.nautilus
      den.aspects.hardware.audio
      den.aspects.hardware.amd-monitoring
      den.aspects.network.avahi
      den.aspects.network.vpn
      den.aspects.virtualization.podman
      den.aspects.services.ydotool
      den.aspects.platform.nh
      den.aspects.platform.nix-ld
      den.aspects.platform.boot-plymouth
    ];
  };
}
