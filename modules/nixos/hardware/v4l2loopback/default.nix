{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) str int;
  cfg = config.${namespace}.hardware.v4l2loopback;
in {
  options.${namespace}.hardware.v4l2loopback = {
    enable = mkEnableOption "v4l2loopback virtual camera support with color correction";

    deviceNumber = mkOption {
      type = int;
      default = 10;
      description = "Video device number for the virtual camera (creates /dev/videoN)";
    };

    deviceName = mkOption {
      type = str;
      default = "VirtualCam";
      description = "Name of the virtual camera device shown in applications";
    };
  };

  config = mkIf cfg.enable {
    # Load v4l2loopback kernel module
    boot.extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];

    boot.kernelModules = ["v4l2loopback"];

    # Configure v4l2loopback options
    boot.extraModprobeConfig = ''
      options v4l2loopback video_nr=${toString cfg.deviceNumber} card_label="${cfg.deviceName}" exclusive_caps=1
    '';

    # Add warmcam script and diagnostic tools to system packages
    environment.systemPackages = [
      pkgs.${namespace}.warmcam
      pkgs.libva-utils
      pkgs.v4l-utils
    ];
  };
}
