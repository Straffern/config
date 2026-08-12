{den, ...}: let
  warmcam = pkgs: pkgs.callPackage ./_package {};
in {
  den.aspects.hardware.v4l2loopback = {
    packages = {pkgs, ...}: {warmcam = warmcam pkgs;};
    nixos = {
      config,
      pkgs,
      ...
    }: {
      boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
      boot.kernelModules = ["v4l2loopback"];
      boot.extraModprobeConfig = ''options v4l2loopback video_nr=10 card_label="VirtualCam" exclusive_caps=1'';
      environment.systemPackages = [
        (warmcam pkgs)
        pkgs.libva-utils
        pkgs.v4l-utils
      ];
    };
  };
}
