{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.virtualisation.podman;
in {
  options.services.virtualisation.podman = {
    enable = mkEnableOption "Podman";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman = {
        enable = true;
        dockerSocket.enable = true;
        dockerCompat = true;
        defaultNetwork.settings = { dns_enabled = true; };
      };
    };
  };
}
