{
  lib,
  stdenvNoCC,
}: let
  images = builtins.attrNames (builtins.readDir ./wallpapers);
  names = map (image: lib.removeSuffix ".${lib.last (lib.splitString "." image)}" image) images;
  wallpapers = lib.genAttrs names (
    name: let
      image =
        lib.findFirst
        (candidate: lib.removeSuffix ".${lib.last (lib.splitString "." candidate)}" candidate == name)
        null
        images;
    in
      ./. + "/wallpapers/${image}"
  );
in
  stdenvNoCC.mkDerivation {
    pname = "wallpapers";
    version = "0.1.0";
    src = ./wallpapers;
    installPhase = ''
      mkdir -p $out/share/wallpapers
      cp -r $src/* $out/share/wallpapers/
    '';
    passthru = {inherit names;} // wallpapers;
  }
