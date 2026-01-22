{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.akvcam;
in {
  options.${namespace}.hardware.akvcam = {
    enable = mkEnableOption "akvcam virtual camera support for webcamoid";
  };

  config = mkIf cfg.enable {
    # Load akvcam kernel module (webcamoid's virtual camera driver)
    boot.extraModulePackages = with config.boot.kernelPackages; [
      akvcam
    ];

    boot.kernelModules = ["akvcam"];

    # Required for webcamoid virtual camera functionality
    security.polkit.enable = true;
  };
}
