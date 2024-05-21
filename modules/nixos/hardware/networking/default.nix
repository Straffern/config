{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.hardware.networking;
in {
  options.hardware.networking = with types; {
    enable = mkBoolOpt false "Enable NetworkManager";
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = true;
    environment.persist.directories = [
      "/etc/NetworkManager"
    ];
  };


#  environment.persist.directories = [
#    "/etc/gdm"
#  ];
}
