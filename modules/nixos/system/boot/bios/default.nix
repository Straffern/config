{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace}; let
  cfg = config.${namespace}.system.boot.bios;
in {
  options.${namespace}.system.boot.bios = with types; {
    enable = mkBoolOpt false "Whether or not to enable bios booting.";
    device =
      mkOpt (nullOr str) null
      "Disk that grub will be installed to. If null, no device will be set.";
  };

  config = mkIf cfg.enable {
    boot.loader.grub =
      {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      }
      // (lib.optionalAttrs (cfg.device != null) {device = cfg.device;});
  };
}
