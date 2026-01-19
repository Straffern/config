{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.audio;
in {
  options.${namespace}.hardware.audio = {enable = mkEnableOption "Pipewire";};

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
      raopOpenFirewall = true;

      # AirPlay (RAOP) Discovery and Stability
      extraConfig.pipewire."20-raop-discover" = {
        "context.modules" = [
          {
            name = "libpipewire-module-raop-discover";
            args = {
              "raop.latency.ms" = 1500;
              "raop.encryption.type" = "RSA";
            };
          }
        ];
      };

      # Bluetooth codec configuration for high-quality voice
      wireplumber.extraConfig."11-bluetooth-policy" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-msbc" = true;
          "bluez5.enable-sbc-xq" = true;
          "bluez5.codecs" = ["ldac" "aptx_hd" "aptx" "aac" "sbc_xq" "sbc"];
        };
      };

      # Global Audio Device Priority Hierarchy
      # Higher priority = preferred when multiple devices available
      wireplumber.extraConfig."11-audio-hierarchy" = {
        "monitor.alsa.rules" = [
          # Internal speakers/mic - base priority
          {
            matches = [{"node.name" = "~alsa_output.pci-*.analog-stereo";}];
            actions = {update-props = {"priority.session" = 1000;};};
          }
          {
            matches = [{"node.name" = "~alsa_input.pci-*.analog-stereo";}];
            actions = {update-props = {"priority.session" = 1000;};};
          }
          # USB webcam mics - slightly higher than internal
          {
            matches = [{"node.name" = "~alsa_input.usb-.*";}];
            actions = {update-props = {"priority.session" = 1500;};};
          }
        ];
        "monitor.bluez.rules" = [
          # Bluetooth devices - highest priority (both input and output)
          {
            matches = [{"node.name" = "~bluez_input.*";}];
            actions = {update-props = {"priority.session" = 2000;};};
          }
          {
            matches = [{"node.name" = "~bluez_output.*";}];
            actions = {update-props = {"priority.session" = 2000;};};
          }
        ];
      };

      # Perceived volume scaling for AirPlay (RAOP) devices
      wireplumber.extraConfig."11-raop-volume" = {
        "monitor.raop.rules" = [
          {
            matches = [{"node.name" = "~raop_sink.*";}];
            actions = {
              update-props = {
                "channelmix.volume-scale" = "cubic";
                "node.max-volume" = 1.0;
              };
            };
          }
        ];
      };
    };
    programs.noisetorch.enable = true;

    networking.firewall = {
      # Supplement for HomePod discovery and handshake
      allowedTCPPorts = [5000 7000 7100];
      # Ensure mDNS is allowed for discovery
      allowedUDPPorts = [5353];
    };

    services.udev.packages = with pkgs; [headsetcontrol];

    environment.systemPackages = with pkgs; [
      pavucontrol

      headsetcontrol
      headset-charge-indicator
      pulsemixer
    ];
  };
}
