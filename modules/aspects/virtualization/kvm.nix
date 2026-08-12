{den, ...}: {
  den.aspects.virtualization.kvm.nixos = {
    host,
    lib,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs; [
      libguestfs
      virtio-win
      win-spice
      virt-manager
      virt-viewer
    ];

    virtualisation = {
      kvmgt.enable = true;
      spiceUSBRedirection.enable = true;

      libvirtd = {
        enable = true;
        allowedBridges = [
          "nm-bridge"
          "virbr0"
        ];
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu.swtpm.enable = true;
      };
    };

    environment.persistence."/persist".directories =
      lib.mkIf (host.hasAspect den.aspects.platform.impermanence)
      ["/var/lib/libvirt"];
  };
}
