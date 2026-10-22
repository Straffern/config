{inputs, ...}: _final: _prev: let
  system = _final.stdenv.hostPlatform.system;
  voxtypeBase = inputs.voxtype.packages.${system};
  # Upstream's startup variant check demands a `soniox` Cargo feature that no
  # longer exists (Soniox is always compiled in), so it warns on every start.
  unwrapped = voxtypeBase.voxtype-onnx-migraphx-unwrapped.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./soniox-variant-check.patch];
  });
in {
  voxtype-soniox = voxtypeBase.onnx-migraphx.overrideAttrs {paths = [unwrapped];};
}
