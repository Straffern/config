# Force Zig CPU baseline for portability across x86_64 hosts.
# Without this, Zig compiles with -mcpu=native (build machine features)
# which crashes on VPS/older CPUs lacking AVX2 etc.
{inputs, ...}: final: _prev: {
  ww = inputs.ww.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    buildPhase =
      builtins.replaceStrings
      ["--release=safe"]
      ["--release=safe -Dcpu=baseline"]
      old.buildPhase;
  });
}
