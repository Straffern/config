{den, ...}: let
  monolisaPackage = pkgs: pkgs.callPackage ./packages/_package/monolisa {};
in {
  den.aspects.styles.monolisa.nixos = {pkgs, ...}: let
    monolisa = monolisaPackage pkgs;
  in {
    fonts.packages = [monolisa];
  };
}
