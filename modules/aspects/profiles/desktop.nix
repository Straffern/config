{den, ...}: {
  den.aspects.profiles.desktop = {
    includes = [
      den.aspects.profiles.common
      den.aspects.styles.fonts-system
      den.aspects.styles.stylix-system
      den.aspects.desktop.base
      den.aspects.desktop.nautilus
      den.aspects.hardware.audio
      den.aspects.hardware.bluetooth
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
