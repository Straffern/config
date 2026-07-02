{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.xdg-portal;
  hyprlandPortalPackage = config.wayland.windowManager.hyprland.portalPackage;
  hyprland-preview-share-picker =
    inputs.hyprland-preview-share-picker.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.${namespace}.desktops.addons.xdg-portal = {
    enable = mkEnableOption "Xdg-portal hyprland & gtk";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = lib.mkForce true;
        xdgOpenUsePortal = true;
        config = {
          common.default = [
            "hyprland"
            "gtk"
          ];
          hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };
        extraPortals = lib.optionals (hyprlandPortalPackage != null) [ hyprlandPortalPackage ] ++ [
          pkgs.xdg-desktop-portal-gtk
        ];
      };
    };

    services.gnome-keyring = {
      enable = true;
      components = [
        "secrets"
        "pkcs11"
      ];
    };

    ${namespace}.system.persistence.directories = [ ".local/share/keyrings" ];

    # Screen share picker: GTK4/Rust alternative to hyprland-share-picker
    # (avoids Qt6 QProxyStyle crash). Requires xdph custom_picker_binary.
    home.packages = [
      hyprland-preview-share-picker
      pkgs.slurp
    ];
    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
        custom_picker_binary = ${lib.getExe' hyprland-preview-share-picker "hyprland-preview-share-picker"}
      }
    '';
  };
}
