{den, ...}: {
  den.aspects.profiles.desktop = {
    includes = [
      den.aspects.profiles.common
      den.aspects.styles.fonts
      den.aspects.styles.stylix
      den.aspects.desktop.base
      den.aspects.desktop.nautilus
      den.aspects.hardware.audio
      den.aspects.hardware.bluetooth
      den.aspects.network.avahi
      den.aspects.network.vpn
      den.aspects.services.ydotool
      den.aspects.platform.nh
      den.aspects.platform.nix-ld
      den.aspects.platform.boot-plymouth
      den.aspects.profiles.development
      den.aspects.platform.nixgl
      den.aspects.desktop.input-tools
      den.aspects.desktop.wayland-session
      den.aspects.desktop.media-controls
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
    nixos = {
      host,
      lib,
      ...
    }: {
      imports = [
        {config = den.aspects.virtualization.podman.nixos {inherit host lib;};}
      ];
    };
  };
}
