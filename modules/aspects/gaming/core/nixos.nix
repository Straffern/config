{den, ...}: {
  den.aspects.gaming.core.nixos = {pkgs, ...}: {
    hardware = {
      # xpadneo.enable = true;
      # xone.enable = true;

      graphics = {
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
    };

    services.ratbagd.enable = true;

    programs = {
      gamemode.enable = true;
      gamescope = {
        enable = true;
        capSysNice = true; # Needed for DRM session scheduling + setuid bwrap
      };
      steam = {
        enable = true;
        package =
          pkgs.steam.override {extraPkgs = p: with p; [mangohud gamemode];};
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;

        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };

    services.xserver.videoDrivers = ["amdgpu"];
    environment.variables = {
      RUSTICL_ENABLE = "radeonsi";
      ROC_ENABLE_PRE_VEGA = "1";
    };

    environment.systemPackages = with pkgs; [
      winetricks
      wineWow64Packages.waylandFull
      adwsteamgtk
      mesa-demos
      vulkan-tools
      clinfo
      ffmpeg
    ];
  };
}
