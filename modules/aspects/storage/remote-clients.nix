{den, ...}: {
  den.aspects.storage.remote-clients.nixos = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.nfs-utils
      pkgs.openiscsi
    ];
  };
}
