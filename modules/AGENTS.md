# Modules knowledge base

`modules/` is the Den aspect/entity tree. Aspects own one concern and compose
through explicit `includes`; entities select the aspects that apply to a host
or integrated user. Native NixOS and Home Manager options are the public
configuration interface.

## Structure

- `aspects/cli/` — shells, editors, multiplexers, terminals, and tools.
- `aspects/desktop/` — graphical environment and desktop services.
- `aspects/platform/`, `security/`, `hardware/`, and `network/` — system
  foundations.
- `aspects/profiles/` — thin composition aspects such as `common`, `desktop`,
  `server`, `development`, `gaming`, `kubernetes`, `social`, `video`, and
  `gamedev`.
- `aspects/services/` — service aspects, including Hermes.
- `entities/hosts/` — `frostmourne`, `palantir`, and `sonic` host entities.
- `_` directories — subordinate expressions/assets owned by their parent
  aspect; they have no independent export semantics.

## Where to look

| Task | Location |
| --- | --- |
| Add a capability | `modules/aspects/<concern>/` |
| Add a host | `modules/entities/hosts/` |
| Add integrated Alex configuration | the Palantir or Sonic host entity |
| Add a profile | `modules/aspects/profiles/` |
| Add a colocated package | the owning aspect's `_package/` |
| Add secret wiring | the owning service/security aspect |

## Conventions

Keep aspects narrow and use native option paths. Compute alternate-input or
custom packages as lexical values and pass them explicitly to the consuming
option; do not mutate the shared package set to create aliases. Use ordinary
`pkgs.callPackage` for local `_package` expressions. Keep Home Manager options
inside integrated host/user composition and NixOS options in system aspects.

The entity system is only `x86_64-linux`. Home Manager is integrated for Alex
on Palantir and Sonic; it is not emitted as a separate output.

## Anti-patterns

- Do not add an implicit output contract based on a directory name.
- Do not publish alternate output families.
- Do not hardcode user paths; use `config.home.homeDirectory` where applicable.
- Do not inline secrets or print decrypted values.
- Do not modify the generated root `flake.nix` by hand; update declaration
  aspects and run `nix run .#write-flake`.
