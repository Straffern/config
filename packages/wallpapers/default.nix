{ pkgs, lib, ... }:
let
  images = builtins.attrNames (builtins.readDir ./wallpapers);
  names =
    builtins.map (lib.snowfall.path.get-file-name-without-extension) images;

  wallpapers = lib.genAttrs names (name:
    let
      image = lib.findFirst
        (img: (lib.snowfall.path.get-file-name-without-extension img) == name)
        null images;
    in ./. + "/wallpapers/${image}");

  installTarget = "$out/share/wallpapers";
in pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src = ./wallpapers;

  installPhase = ''
    mkdir -p ${installTarget}
    find * -type f -mindepth 0 -maxdepth 0 -exec cp ./{} ${installTarget}/{} ';'
  '';

  passthru = { inherit names; } // wallpapers;
}
