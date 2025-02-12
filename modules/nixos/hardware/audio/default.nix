{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.audio;
in {
  options.${namespace}.hardware.audio = { enable = mkEnableOption "Pipewire"; };

  config = mkIf cfg.enable {
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
    };
    programs.noisetorch.enable = true;

    services.udev.packages = with pkgs; [ headsetcontrol ];

    environment.systemPackages = with pkgs; [
      pavucontrol

      headsetcontrol
      headset-charge-indicator
      pulsemixer
    ];

  };
}
