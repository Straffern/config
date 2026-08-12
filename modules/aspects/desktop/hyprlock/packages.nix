{den, ...}: let
  hyprlockRecoverPackage = pkgs: pkgs.callPackage ./_hyprlock-recover {};
in {
  den.aspects.desktop.hyprlock.packages = {pkgs, ...}: {
    hyprlock-recover = hyprlockRecoverPackage pkgs;
  };
}
