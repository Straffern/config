{den, ...}: let
  monolisaPackage = pkgs: pkgs.callPackage ./packages/_package/monolisa {};
in {
  den.aspects.styles.monolisa = {
    packages = {pkgs, ...}: {
      monolisa = monolisaPackage pkgs;
    };

    nixos = {pkgs, ...}: {
      fonts.packages = [
        (monolisaPackage pkgs)
      ];
    };
  };
}
