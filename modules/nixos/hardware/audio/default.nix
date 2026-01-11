{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.audio;
in {
  options.${namespace}.hardware.audio = { enable = mkEnableOption "Pipewire"; };

  config = mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;

      # Bluetooth codec configuration for high-quality voice
      wireplumber.extraConfig."11-bluetooth-policy" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-msbc" = true;
          "bluez5.enable-sbc-xq" = true;
          "bluez5.codecs" = [ "ldac" "aptx_hd" "aptx" "aac" "sbc_xq" "sbc" ];
        };
      };

      # Global Microphone Priority Hierarchy
      wireplumber.extraConfig."11-microphone-hierarchy" = {
        "monitor.alsa.rules" = [
          # Internal mic - base priority
          {
            matches = [{ "node.name" = "~alsa_input.pci-*.analog-stereo"; }];
            actions = { update-props = { "priority.session" = 1000; }; };
          }
          # Webcams - slightly higher than internal
          {
            matches = [{ "node.name" = "~alsa_input.usb-.*webcam.*"; }];
            actions = { update-props = { "priority.session" = 1500; }; };
          }
        ];
        "monitor.bluez.rules" = [
          # Bluetooth headsets - higher than internal/webcam
          {
            matches = [{ "node.name" = "~bluez_input.*"; }];
            actions = { update-props = { "priority.session" = 2000; }; };
          }
        ];
      };
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
