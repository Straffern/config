{inputs, ...}: final: _prev: {
  opencode-patched =
    inputs.opencode-patched.packages.${final.stdenv.hostPlatform.system}.opencode.overrideAttrs
    (old: {
      patches = (old.patches or []) ++ [../../patches/opencode-elixir-treesitter.patch];
    });
}
