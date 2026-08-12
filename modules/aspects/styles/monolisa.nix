{den, ...}: let
  monolisaPackage = pkgs: pkgs.callPackage ./_monolisa {};
in {
  den.aspects.styles.monolisa.nixos = {pkgs, ...}: let
    monolisa = monolisaPackage pkgs;
  in {
    fonts.packages = [monolisa];
  };
}
