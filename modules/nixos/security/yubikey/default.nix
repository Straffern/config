{ config, pkgs, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.security.yubikey;
in {
  options.${namespace}.security.yubikey = {
    enable = mkEnableOption "Yubikey for auth.";
  };

  config = mkIf cfg.enable {
    services = {
      pcscd.enable = true;
      udev.packages = with pkgs; [ yubikey-personalization ];
      dbus.packages = [ pkgs.gcr ];

      # INFO: lock PC on yubikey removal
      udev.extraRules = ''
        ACTION=="remove",\
         ENV{ID_BUS}=="usb",\
         ENV{ID_MODEL_ID}=="0407",\
         ENV{ID_VENDOR_ID}=="1050",\
         ENV{ID_VENDOR}=="Yubico",\
         RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';
    };

    security.pam.services = {
      swaylock = { u2fAuth = true; };

      hyprlock = { u2fAuth = true; };

      login = { u2fAuth = true; };

      sudo = { u2fAuth = true; };
    };
  };
}
