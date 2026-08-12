# Systems knowledge base

Host identity entities live under `modules/entities/hosts/` and target the one
Den entity system, `x86_64-linux`. The three NixOS hosts are `frostmourne`,
`palantir`, and `sonic`.

## Host contract

- Palantir and Sonic each declare Alex as an integrated Home Manager user;
  Frostmourne has no user configuration.
- Host entities select aspects explicitly and retain host-local hardware,
  deployment, and metadata details.

## Where to look

- `modules/entities/hosts/<host>.nix` — host entity and selected aspects.
- Host-local `_` paths — generated hardware, disks, and subordinate data.
- `modules/aspects/hardware/` — reusable hardware capabilities.
- `modules/aspects/deployment/` — explicit deploy metadata.

## Rules

Use native NixOS and Home Manager options. Keep host files focused on identity,
membership, hardware, and explicit aspect selection. Do not change
`system.stateVersion` during routine updates. Avoid `/dev/sdX`; use UUIDs or
labels in disk configuration. Keep secrets encrypted with SOPS/age and never
place values inline.

The generated root `flake.nix` is not hand-edited. After declaration changes,
run `nix run .#write-flake`; the staleness check requires byte-identical output.
If generation cannot start, run the pinned recovery bootstrap first:

```bash
nix-shell https://github.com/denful/flake-file/archive/v0.6.0.tar.gz -A flake-file.sh --run bootstrap
nix run .#write-flake
```
