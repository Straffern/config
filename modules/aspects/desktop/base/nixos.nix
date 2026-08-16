{den, ...}: {
  den.aspects.desktop.base.user.extraGroups = ["video" "input" "tty"];
  den.aspects.desktop.base.nixos = {pkgs, ...}: {
    boot.binfmt.emulatedSystems = ["aarch64-linux"];
    environment.systemPackages = [pkgs.libnotify];
    services.upower.enable = true;
  };
}
