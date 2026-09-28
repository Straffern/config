{den, ...}: {
  den.aspects.virtualization.kvm.nixos = {
    lib,
    host,
    pkgs,
    ...
  }:
    lib.mkMerge [
      {
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

        # libvirt's virt-secret-init-encryption writes into libvirtd-config's StateDirectory
        # (/var/lib/libvirt/secrets) but is not ordered after it, so a fresh boot can race and fail.
        systemd.services.virt-secret-init-encryption = {
          wants = ["libvirtd-config.service"];
          after = ["libvirtd-config.service"];
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        environment.persistence."/persist".directories = ["/var/lib/libvirt"];
      })
    ];
  den.aspects.virtualization.kvm.user.extraGroups = ["kvm" "libvirtd"];
}
