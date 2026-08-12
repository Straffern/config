{den, ...}: let
  monolisaPackage = pkgs: pkgs.callPackage ./_package/monolisa {};
  wallpapersPackage = pkgs: pkgs.callPackage ./_package/wallpapers {};
in {
  den.aspects.styles.packages = {
    packages = {pkgs, ...}: {
      monolisa = monolisaPackage pkgs;
      wallpapers = wallpapersPackage pkgs;
    };
  };
}
