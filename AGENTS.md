# Project knowledge base

NixOS dotfiles use one Den entity/aspect/policy architecture with flake-parts.
The generated root `flake.nix` is committed and written by flake-file; edit
aspect-owned declaration modules, not the generated file.

## Structure

- `modules/` — Den aspects and entities, including host and user composition.
- `modules/entities/hosts/` — `frostmourne`, `palantir`, and `sonic`.
- `modules/aspects/` — concern-owned aspects and profiles.
- `_` subdirectories — colocated private packages, assets, patches, and data.
- `docs/` and `notes/` — operational and historical documentation.

## Contract

The only entity system is `x86_64-linux`. Alex is an integrated Home Manager
user on Palantir and Sonic. Frostmourne declares Alex and Niko as home-less
Den users. Home Manager is host-integrated rather than emitted as a separate
output. Use native
NixOS/Home Manager options and ordinary lexical package values; directory
presence does not create outputs.

Public packages are exactly: `amd-debug-tools`, `btop`, `clipy`,
`gh-fork-cleanup`, `jj-starship`, `kitty-same-cwd`, `lazyjournal`, `monolisa`,
`supermaven-jj-git-shim`, `waldl`, `wallpapers`, and `warmcam`. flake-file also
exports generator packages `write-flake`, `write-inputs`, and `write-lock`. No
additional public output family exists.

## Generated-root workflow

```bash
nix run .#write-flake
```

A second run must leave the generated root byte-identical; the exported
staleness check enforces this. Review generated input/follow/cache changes
before updating `flake.lock`. If the root is missing or cannot evaluate,
restore the last committed generated root or run:

```bash
nix-shell https://github.com/denful/flake-file/archive/v0.7.0.tar.gz -A flake-file.sh --run bootstrap
nix run .#write-flake
```

Never place secrets in generated options and never enable lock pruning or
flattening.

## Safe operations

Use `jj` for repository history. Do not edit `flake.lock` by hand. Do not
modify `system.stateVersion` except through an intentional upgrade procedure.
Keep secrets encrypted with SOPS/age and never print their values.

```bash
nh os switch
nix flake update
nh clean
```