{ inputs, ... }:
_final: _prev:
let
  system = _final.stdenv.hostPlatform.system;
  voxtypeBase = inputs.voxtype.packages.${system};
in
{
  voxtype-soniox = voxtypeBase.onnx-migraphx;
}
