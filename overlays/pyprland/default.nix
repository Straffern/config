{inputs, ...}: _final: prev: {
  pyprland =
    inputs.pyprland.packages.${prev.stdenv.hostPlatform.system}.default;
}
