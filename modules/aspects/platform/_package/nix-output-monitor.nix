{
  fetchpatch,
  haskell,
  nix-output-monitor,
}:
# Determinate Nix 3.23 emits activity type 10113 (OTel traces), which nom 2.2.0 rejects on every line.
# Drop once a nom release includes maralorn/nix-output-monitor#321.
nix-output-monitor.override {
  extraComposeFunctions = [
    (haskell.lib.compose.appendPatch (fetchpatch {
      url = "https://github.com/maralorn/nix-output-monitor/compare/c40cb120262d9e9b1b988898708b124f6ffc0913...d48ff7935da72a5a5764ee8c5358d38417b0f337.diff";
      relative = "nix-output-monitor";
      hash = "sha256-vB/ThII0j99G6j6PKiAtf2bDAYGd6w7WGjcCvQiKOpc=";
    }))
  ];
}
