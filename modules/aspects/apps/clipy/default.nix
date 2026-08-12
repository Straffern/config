{den, ...}: let
  clipy = pkgs: pkgs.callPackage ./_package {};
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
