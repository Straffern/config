# 1. Copy openclaw.plugin.json manifests into dist/extensions/.
#    Upstream build (tsdown) only emits .js — the JSON manifests stay in
#    source extensions/ and never land in dist/, so the runtime can't
#    discover any built-in plugins.
#
# 2. Install the external OpenViking context-engine plugin into extensions/.
#    Symlinked into the state dir at runtime so openclaw discovers it as a
#    user plugin.  @sinclair/typebox resolves from the package's node_modules
#    via normal Node.js resolution (walks up from the real path).
{inputs, ...}: _final: prev: let
  ovPluginSrc = "${inputs.openviking}/examples/openclaw-plugin";
  ovPluginFiles = [
    "index.ts"
    "client.ts"
    "config.ts"
    "context-engine.ts"
    "memory-ranking.ts"
    "process-manager.ts"
    "text-utils.ts"
    "openclaw.plugin.json"
    "package.json"
    "tsconfig.json"
  ];
in {
  openclaw-gateway = prev.openclaw-gateway.overrideAttrs (old: {
    # Append to installPhase (not postInstall — upstream replaces the
    # default phase function, so runHook postInstall never fires).
    installPhase =
      old.installPhase
      + "\n"
      + ''
        # ── Copy built-in plugin manifests into dist/ ──
        for dir in "$out"/lib/openclaw/extensions/*/; do
          ext="$(basename "$dir")"
          target="$out/lib/openclaw/dist/extensions/$ext"
          if [ -d "$target" ] && [ -f "$dir/openclaw.plugin.json" ]; then
            cp "$dir/openclaw.plugin.json" "$target/"
          fi
        done

        # ── Install OpenViking context-engine plugin ──
        mkdir -p "$out/lib/openclaw/extensions/openviking"
        ${builtins.concatStringsSep "\n" (map (f: ''
          cp "${ovPluginSrc}/${f}" "$out/lib/openclaw/extensions/openviking/"
        '') ovPluginFiles)}
      '';
  });
}
