{ inputs, ... }:
_final: _prev:
let
  system = _final.stdenv.hostPlatform.system;
  voxtypeBase = inputs.voxtype.packages.${system};
  voxtypeUnwrapped = voxtypeBase.voxtype-onnx-rocm-unwrapped.overrideAttrs (old: {
    buildFeatures = (old.buildFeatures or [ ]) ++ [ "soniox" ];
    cargoBuildFeatures = (old.cargoBuildFeatures or old.buildFeatures or [ ]) ++ [ "soniox" ];
    cargoCheckFeatures = (old.cargoCheckFeatures or old.checkFeatures or old.buildFeatures or [ ]) ++ [
      "soniox"
    ];
  });
in
{
  voxtype-soniox = voxtypeBase.onnx-rocm.overrideAttrs (_old: {
    paths = [ voxtypeUnwrapped ];
  });
}
