{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) str nullOr;
  cfg = config.${namespace}.hardware.hidraw;
in {
  options.${namespace}.hardware.hidraw = {
    enable = mkEnableOption "HID raw device access for keyboard firmware/configuration tools";
    user = mkOption {
      type = nullOr str;
      default = null;
      description = "User to add to hidraw group (required when enabled)";
    };
  };

  config = mkIf cfg.enable {
    # Validation - make user required
    assertions = [
      {
        assertion = cfg.user != null;
        message = "${namespace}.hardware.hidraw.user must be set when hardware.hidraw is enabled";
      }
    ];

    users.groups.hidraw = {};

    users.users.${cfg.user}.extraGroups = [ "hidraw" ];

    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="hidraw"
    '';

    environment.systemPackages = with pkgs; [
      # Optional: Could add device-specific tools here
      # Many modern keyboards work through browser-based firmware tools
    ];
  };
}