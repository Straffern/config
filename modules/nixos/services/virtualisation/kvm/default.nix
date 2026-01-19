{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.virtualisation.kvm;
in {
  options.${namespace}.services.virtualisation.kvm = {
    enable = mkEnableOption "KVM virtualisation";
  };

  config = mkIf cfg.enable {
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
        allowedBridges = ["nm-bridge" "virbr0"];
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          swtpm.enable = true;
        };
      };
    };

    # Persist VM definitions, storage pools, networks, and secrets
    ${namespace}.system.impermanence.directories = ["/var/lib/libvirt"];
  };
}
