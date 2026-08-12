{den, ...}: let
  monolisaPackage = pkgs: pkgs.callPackage ./_monolisa {};
  wallpapersPackage = pkgs: pkgs.callPackage ./_wallpapers {};
in {
  den.aspects.styles.packages = {
    packages = {pkgs, ...}: {
      monolisa = monolisaPackage pkgs;
      wallpapers = wallpapersPackage pkgs;
    };
  };
}
