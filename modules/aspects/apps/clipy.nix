{den, ...}: let
  clipy = pkgs: pkgs.callPackage ./_clipy {};
in {
  den.aspects.apps.clipy = {
    homeManager = {pkgs, ...}: {
      home.packages = [(clipy pkgs)];
    };

    packages = {pkgs, ...}: {
      clipy = clipy pkgs;
    };
  };
}
