{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.niri = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.desktop.niri.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) getExe mkForce;
    niriBlurAppendix = ''
      blur {
        passes 3
        offset 3.0
        noise 0.02
        saturation 1.5
      }
    '';
  in {
    imports = [inputs.niri.homeModules.niri];
    programs.niri.enable = true;
    # Use same updated niri input for runtime package and config validation.
    programs.niri = {
      package = pkgs.niri;
      # Keep only compositor integration here. DMS owns desktop preferences.
      config = ''
        xwayland-satellite {
          path "${getExe inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable}"
        }
        environment {
          QT_QPA_PLATFORMTHEME "qt6ct"
          QT_QPA_PLATFORMTHEME_QT6 "qt6ct"
        }
      '';
    };

    xdg.configFile.niri-config.source = mkForce (
      inputs.niri.lib.internal.validated-config-for pkgs config.programs.niri.package ''
        ${config.programs.niri.finalConfig}
        ${niriBlurAppendix}
      ''
    );

    # Prefer portal for xdg-open (NixOS programs.niri handles portal packages)
    xdg.portal.xdgOpenUsePortal = true;
  };
}
