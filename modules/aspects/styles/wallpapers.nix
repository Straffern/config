{den, ...}: let
  wallpapersPackage = pkgs: pkgs.callPackage ./packages/_package/wallpapers {};
in {
  den.aspects.styles.wallpapers.packages = {pkgs, ...}: {
    wallpapers = wallpapersPackage pkgs;
  };
}
