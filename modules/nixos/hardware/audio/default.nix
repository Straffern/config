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

      # Global Audio Device Priority Hierarchy
      # Higher priority = preferred when multiple devices available
      wireplumber.extraConfig."11-audio-hierarchy" = {
        "monitor.alsa.rules" = [
          # Internal speakers/mic - base priority
          {
            matches = [{ "node.name" = "~alsa_output.pci-*.analog-stereo"; }];
            actions = { update-props = { "priority.session" = 1000; }; };
          }
          {
            matches = [{ "node.name" = "~alsa_input.pci-*.analog-stereo"; }];
            actions = { update-props = { "priority.session" = 1000; }; };
          }
          # USB webcam mics - slightly higher than internal
          {
            matches = [{ "node.name" = "~alsa_input.usb-.*"; }];
            actions = { update-props = { "priority.session" = 1500; }; };
          }
        ];
        "monitor.bluez.rules" = [
          # Bluetooth devices - highest priority (both input and output)
          {
            matches = [{ "node.name" = "~bluez_input.*"; }];
            actions = { update-props = { "priority.session" = 2000; }; };
          }
          {
            matches = [{ "node.name" = "~bluez_output.*"; }];
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
