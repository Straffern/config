{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.hyprland-preview-share-picker = {
    url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.desktop.addons.xdg-portal = {
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      hyprlandPortalPackage = config.wayland.windowManager.hyprland.portalPackage;
      hyprland-preview-share-picker =
        inputs.hyprland-preview-share-picker.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in {
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
              "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
            };
          };
          extraPortals =
            lib.optionals (hyprlandPortalPackage != null) [hyprlandPortalPackage]
            ++ [
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
  };
}
