{den, ...}: let
  hyprlockRecoverPackage = pkgs: pkgs.callPackage ./_package {};
in {
  den.aspects.desktop.hyprlock.packages = {pkgs, ...}: {
    hyprlock-recover = hyprlockRecoverPackage pkgs;
  };
}
