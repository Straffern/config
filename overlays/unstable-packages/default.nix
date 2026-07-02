{ inputs, ... }:
_final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  unstablePkgs = import inputs.unstable {
    localSystem = { inherit system; };
    inherit (prev) config;
  };
in
{
  hyprpaper = inputs.hyprpaper.packages.${system}.hyprpaper;
  jjui = inputs.jjui.packages.${system}.jjui;

  inherit (unstablePkgs)
    bun
    television
    jujutsu
    hyprlock
    hypridle
    hyprpicker
    niri
    quickshell
    uwsm
    dgop
    ;
}
