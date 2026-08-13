{den, ...}: {
  den.aspects.desktop.base-system.nixos = {pkgs, ...}: {
    boot.binfmt.emulatedSystems = ["aarch64-linux"];
    environment.systemPackages = [pkgs.libnotify];
    services.upower.enable = true;
  };
}
