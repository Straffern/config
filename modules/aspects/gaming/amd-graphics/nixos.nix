{den, ...}: {
  den.aspects.gaming.amd-graphics.nixos = {pkgs, ...}: {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        libva
        libvdpau-va-gl
        vulkan-loader
        vulkan-validation-layers
        mesa.opencl # Enables Rusticl (OpenCL) support
        rocmPackages.clr.icd
      ];
    };

    services.xserver.videoDrivers = ["amdgpu"];

    environment = {
      variables = {
        RUSTICL_ENABLE = "radeonsi";
        ROC_ENABLE_PRE_VEGA = "1";
      };
      systemPackages = with pkgs; [
        mesa-demos
        vulkan-tools
        clinfo
      ];
    };
  };
}
