# Packages knowledge base

Packages are explicit Den aspect outputs, not directory-driven exports. Each
owning aspect computes a lexical derivation and contributes only its approved
public result. Local expressions belong in the aspect's `_package/` path and
use ordinary `pkgs.callPackage`.

## Public output contract

`packages.x86_64-linux` contains exactly these 16 keys:

- `amd-debug-tools`
- `btop`
- `clipy`
- `gh-fork-cleanup`
- `hermes-link`
- `hyprlock-recover`
- `jj-ryu`
- `jj-starship`
- `kitty-same-cwd`
- `lazyjournal`
- `monolisa`
- `supermaven-jj-git-shim`
- `waldl`
- `wallpapers`
- `warmcam`
- `xurl`

Private builders (including provider tools, patched tools, fetched assets, and
service-only dependencies) remain lexical values under their owning aspects and
must not become public package keys. `wallpapers.windows-error` remains a
passthru of the public `wallpapers` derivation.

## Conventions

Use a normal flake-parts `pkgs` with unfree support configured once. Access
alternate-input packages lexically and set explicit upstream `package` options.
Do not mutate the shared package set merely to create convenient names. Keep
package-specific customization private to its owner; no extra public output
family exists.

The generated root `flake.nix` is committed and never hand-edited. Update
aspect-owned declarations and regenerate:

```bash
nix run .#write-flake
```

The writer's second run must be byte-identical; use the exported staleness
check. If the generated root is missing or broken, run:

```bash
nix-shell https://github.com/denful/flake-file/archive/v0.6.0.tar.gz -A flake-file.sh --run bootstrap
nix run .#write-flake
```

Review generated changes before updating `flake.lock`; do not enable lock
pruning or flattening. Never expose source secrets in package expressions.
