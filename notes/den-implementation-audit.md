# Den implementation audit (post–Snowfall Lib)

Primary-source comparison of this flake against official Den docs and
templates, plus leftover seams from the Snowfall Lib migration.

Sources: Den `main` clone at `/tmp/pi-github-repos/denful/den@main` (guides,
tutorials, reference, explanation, templates, and policy modules). Local tree
is `/home/alex/.dotfiles`.

## Canonical Den model

Den is aspect-oriented: you write features, not host files. A pipeline
resolves aspects into NixOS / Darwin / Home Manager configurations.
[`docs/overview.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/overview.mdx)

| Concept | Canonical form | Source |
| --- | --- | --- |
| Hosts | `den.hosts.<system>.<name>` | [`guides/declare-hosts.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/declare-hosts.mdx) |
| Users | `den.hosts.<system>.<name>.users.<user>` | same |
| Standalone homes | `den.homes.<system>.<name>` → `homeConfigurations` | [`guides/home-manager.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/home-manager.mdx) |
| Aspects | `den.aspects.<name>.{nixos,homeManager,includes,provides}` | [`guides/configure-aspects.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/configure-aspects.mdx) |
| Includes | typed aspect refs, not file paths | [`explanation/coming-from.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/explanation/coming-from.mdx) |
| Mutual host↔user | `provides.to-users` / `provides.<user>` / `provides.to-hosts` | [`guides/mutual.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/mutual.mdx) |
| Defaults | `den.default` for `stateVersion` and global includes | [`guides/from-zero-to-den.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/from-zero-to-den.mdx) |
| User HM class | `den.schema.user.classes = ["homeManager"]` | [`guides/home-manager.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/home-manager.mdx) |
| Batteries | `define-user`, `hostname`, `primary-user`, `user-shell`, `unfree`, `inputs'` | [`guides/batteries.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/batteries.mdx) |
| Parametric dispatch | `{ host }` / `{ host, user }` instead of `mkIf` / `specialArgs` | [`explanation/parametric.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/explanation/parametric.mdx) |
| Packages | aspect `packages` class + schema includes; flake-parts uses `packages-to-flake-parts` | [`reference/output.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/reference/output.mdx), [`modules/policies/flake-parts.nix`](https://github.com/denful/den/blob/main/modules/policies/flake-parts.nix) |
| Dendritic flake-file | import `flake-file.flakeModules.dendritic` **and** `den.flakeModules.dendritic` | [`templates/default/modules/dendritic.nix`](https://github.com/denful/den/blob/main/templates/default/modules/dendritic.nix) |

Recommended 3-host + integrated HM layout, from `templates/default`:

- `modules/dendritic.nix` — flake-file + Den dendritic modules and root inputs
- `modules/defaults.nix` — `den.default` + `den.schema.user.classes`
- `modules/hosts.nix` (or per-host files) — `den.hosts.<system>.<name>.users.<user> = {}`
- host aspect with `nixos` + `provides.to-users` / `provides.<user>`
- user aspect with `define-user` / `primary-user` / `user-shell` + `homeManager`

Host-scope `homeManager` content does **not** leak to users. After that
resolver change, home content must be routed through `provides`, a
`to-users` policy, or the host-aspects battery.
[`guides/home-manager.mdx` “Host-scope parametric aspects no longer deliver homeManager content to users”](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/home-manager.mdx)

`specialArgs` is not the Den equivalent of host/user data. Context is a real
function argument applied before module evaluation.
[`explanation/coming-from.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/explanation/coming-from.mdx)

## Current implementation map

### Wiring

| File | Role |
| --- | --- |
| `modules/dendritic.nix` | flake-file options, generated `flake.nix` outputs, root inputs |
| `modules/defaults.nix` | `stateVersion` 26.05, global `allowUnfree`, `define-user`, user class `homeManager` |
| `modules/output-routing.nix` | flake-parts package routing + curated `den.aspects.outputs` allowlist |
| `modules/entities/hosts/*` | host entities, deploy-rs nodes, host aspects |
| `modules/aspects/identity/alex` | shared Alex user aspect |
| `modules/aspects/profiles/*` | thin include-graphs (`common`, `desktop`, `server`, …) |
| `flake.nix` | generated; `import-tree ./modules` via flake-parts |

Entity system is only `x86_64-linux`. Home Manager is host-integrated for Alex
on Palantir and Sonic; there is no `den.homes` and no `homeConfigurations`
output. That matches the repo contract in `README.md` / `AGENTS.md`.

### Host / user composition

```
frostmourne (no den users)
  includes: profiles.kubernetes → server → common
            platform.boot, _frostmourne-users (raw users.users.alex/niko)

palantir.users.alex = {}
  host includes: profiles.server, hermes, hindsight, tailscale, podman, …
  provides.alex: profiles.development, zsh, opencode, git, stylix, clipy, _palantir-home

sonic.users.alex = {}
  host includes: profiles.desktop, gaming, niri, dms, …
  provides.alex: profiles.desktop (again), social, niri, dms, cli extras, _sonic-home
```

`den.aspects.alex` is picked up automatically because `user.aspect` defaults to
the user name. [`guides/declare-hosts.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/declare-hosts.mdx)

Alex includes `primary-user` and `user-shell "zsh"`, which is the template
pattern. [`templates/default/modules/tux.nix`](https://github.com/denful/den/blob/main/templates/default/modules/tux.nix)

### What is already idiomatic

- Dendritic `import-tree ./modules` with `_` dirs ignored. [`guides/from-zero-to-den.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/from-zero-to-den.mdx)
- Concern-owned aspects + thin profile include-graphs.
- Host-local Disko / facter / hardware via `imports` inside `den.aspects.<host>.nixos`.
- Lexical `pkgs.callPackage ./_package` instead of overlay aliases (stated in `modules/AGENTS.md`).
- `host.hasAspect` in class modules (`hindsight`, `k3s`, `tailscale`, bluetooth, kvm, podman, sops persistence). Flat-form `{ host, lib, pkgs, ... }` is documented. [`explanation/class-modules.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/explanation/class-modules.mdx)
- Aspect-owned `flake-file.inputs` colocated with the consumer.
- Public package allowlist via `den.aspects.outputs` + `packages-to-flake-parts` (intentional, not accidental Snowfall auto-export).
- No `lib.snowfall`, no `extraSpecialArgs`, no `den.ctx` (already on the current API). [`guides/migrate-ctx.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/migrate-ctx.mdx)

## Improvement candidates

Ranked by how far they sit from current Den, not by how hard they are.

### 1. Dual-include of mixed profiles (highest)

Sonic includes `profiles.desktop` on the **host** and again on `provides.alex`.
Palantir is closer to the docs: host gets `profiles.server`, Alex gets
`profiles.development`.

Host-scope `homeManager` is inert. [`guides/home-manager.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/home-manager.mdx)
So the double include is compensating: host include delivers `nixos`, user
provide delivers `homeManager`. That works, but:

- Mixed profiles (`common`, `desktop`, `development`) carry both classes.
- Including them at host scope silently drops home content.
- Including them at user scope can re-apply `nixos` via the user→host path.

Canonical split from the default template:

- Host aspect `includes` = OS concerns; `provides.to-users` / `provides.alex` = home concerns.
- Or keep mixed profiles but include each profile in **one** scope only, and use `provides.to-users.homeManager` for the home half. [`guides/mutual.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/mutual.mdx), [`templates/default/modules/igloo.nix`](https://github.com/denful/den/blob/main/templates/default/modules/igloo.nix)

`profiles.common` currently lists Brave and Helium (`homeManager`-only) next to
OpenSSH and NetworkManager. On Palantir/Frostmourne that home half never
applies. On Sonic it applies only because of the duplicate include.

### 2. Frostmourne users are not Den users

`den.hosts.x86_64-linux.frostmourne = {}` has no `users.*`. Login accounts live
in `den.aspects._frostmourne-users` as raw `users.users.alex` / `niko`,
duplicating groups from `den.aspects.alex`.

Canonical: declare `users.alex` / `users.niko` on the host and set
`classes = []` or `["user"]` so they stay home-less.
[`guides/declare-hosts.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/declare-hosts.mdx)
Default user class is `["user"]`; this repo overrides all users to
`homeManager` in `modules/defaults.nix`, so a Frostmourne user would need an
explicit class override.

Private `_frostmourne-users` / `_palantir-home` / `_sonic-home` names are fine
as host-local provides; the issue is skipping the user entity.

### 3. Dendritic bootstrap is hand-rolled

Default template:

```nix
imports = [
  (inputs.flake-file.flakeModules.dendritic or { })
  (inputs.den.flakeModules.dendritic or { })
];
```

This repo instead imports `flake-file/modules/options` and `write-flake.nix`
directly, then redefines `apps`, `intoPath`, `preProcess`, and:

```nix
config.flake-file.outputs = ''inputs: builtins.removeAttrs (inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)) [ "overlays" ]'';
```

`removeAttrs … ["overlays"]` is the clearest Snowfall leftover: Snowfall Lib
emits an `overlays` output family; Den does not. The public contract already
forbids extra output families (`README.md`).

Candidate: switch to `flake-file.flakeModules.dendritic` +
`den.flakeModules.dendritic`, and drop the overlay strip if nothing still
produces `overlays`. Keep a one-line comment if the strip must stay until
confirmed empty.

### 4. Unused batteries / stringly host identity

Used: `define-user`, `primary-user`, `user-shell`.

Unused but documented for this shape of flake:

| Battery | Why it fits |
| --- | --- |
| `den.batteries.hostname` | replace `networking.hostName = "palantir"` etc. [`guides/batteries.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/batteries.mdx) |
| `den.batteries.unfree [ … ]` | replace global `allowUnfree = true` |
| `den.batteries.inputs'` / `self'` | flake-parts specialized inputs as module args |
| `user` class (`os-user`) | `den.aspects.alex.user.extraGroups` instead of `nixos.users.users.alex` [`reference/batteries.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/reference/batteries.mdx) |

`config.networking.hostName == "palantir"` in Hermes and Hindsight is the
pre-Den `mkIf` style. Prefer `host.name`, a Palantir-only include, or
`provides` from `den.aspects.palantir`.
[`explanation/parametric.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/explanation/parametric.mdx)

`hardware.hidraw` hardcodes `users.users.alex.extraGroups`. A `{ user, ... }`
aspect, or extraGroups on `den.aspects.alex`, would apply to whichever user is
in scope.

### 5. `programs.home-manager.enable` on integrated HM

`modules/aspects/platform/core.nix` sets `programs.home-manager.enable = true`
and Palantir's host NixOS module adds `pkgs.home-manager` to systemPackages.
Integrated HM is forwarded into `home-manager.users.<name>` by the battery; the
CLI package is for standalone `homeConfigurations`.
[`guides/home-manager.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/home-manager.mdx)

Same file hardcodes `NH_FLAKE = "/home/${config.home.username}/.dotfiles"`,
which `modules/AGENTS.md` already flags (use `config.home.homeDirectory`).

### 6. Snowfall-shaped leaf explosion

`profiles.development` includes ~80 one-file CLI aspects (`fd.nix`, `jq.nix`,
…). That is the Snowfall `packages/` / `modules/` leaf convention, not Den's
“one concern” unit. [`explanation/aspects.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/explanation/aspects.mdx)

`gui-leaves.nix` and `video-gamedev.nix` still use the Snowfall “leaves” name
and bundle many tiny aspects in one file.

Candidates:

- Collapse trivial `home.packages = [ pkgs.foo ]` leaves into a few bag
  aspects (`cli.modern-unix`, `apps.desktop-utilities`).
- Keep real concerns (jj, neovim, hermes, niri) as their own aspects.

### 7. Dead / unattached aspects

Never included by any host or profile:

- `den.aspects.profiles.gamedev` / `profiles.video`
- `den.aspects.desktop.hyprland` (Sonic runs niri + dms; tuigreet still talks
  about Hyprland)
- `den.aspects.cli.zellij` (large module, not in `profiles.development`)

Either attach them or delete/archive. Hyprlock recover is still a public
package, so hyprland-adjacent packages are not automatically dead.

### 8. Output routing is extra policy, not wrong

Default flake-system schema includes `packages-to-flake` (direct
`flake.packages.<system>`). This repo **excludes** that and includes
`system-to-flake-parts` + `packages-to-flake-parts`, then lists package-producing
aspects on `den.aspects.outputs`.
[`modules/policies/flake.nix`](https://github.com/denful/den/blob/main/modules/policies/flake.nix),
[`modules/policies/flake-parts.nix`](https://github.com/denful/den/blob/main/modules/policies/flake-parts.nix)

That matches the documented public-package set. The hacky part is the extra
indirection (`aspects.outputs` as a synthetic aggregator). A cleaner Den-native
form is `den.schema.flake-parts.includes = [ packages-to-flake-parts, clipy, … ]`
without a wrapper aspect, or keep the wrapper but document it as the allowlist
mechanism (already in `README.md`).

`den.aspects.deployment.flake-parts` for deploy-rs checks is a valid custom
class / flake-parts forward. [`guides/custom-classes.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/custom-classes.mdx),
[`tutorials/flake-parts-modules.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/tutorials/flake-parts-modules.mdx)

`options.denful.deployment.nodes` is a local option tree, not a Den namespace
(`den.ful.<name>`). Fine as private config; rename only if you want it to be a
shareable namespace. [`guides/namespaces.mdx`](https://github.com/denful/den/blob/main/docs/src/content/docs/guides/namespaces.mdx)

### 9. Optional Den surfaces not used (not bugs)

- Quirks / pipes for cross-aspect data (firewall ports example). Persistence
  currently uses `host.hasAspect` instead, which is also first-party.
- Angle-bracket `<aspect/path>` syntax. Style only.
- `den.homes` standalone outputs. Intentionally omitted.
- Namespaces / `den.ful` export. Single-flake repo, not needed yet.

## Suggested order

1. Stop double-including mixed profiles; route home via `provides.alex` /
   `provides.to-users` only.
2. Declare Frostmourne users as Den users with no Home Manager class.
3. Replace `networking.hostName == "palantir"` and hardcoded `users.users.alex`
   with `host` / `user` context or host-owned includes.
4. Align `dendritic.nix` with `templates/default`; drop overlay stripping if
   unused.
5. Adopt `hostname` (and maybe `unfree` / `user` class) batteries.
6. Collapse trivial CLI leaves; attach or remove hyprland / zellij / video /
   gamedev.

Do not treat overlay-free lexical packages, `_` colocated assets, or the
curated public package list as Snowfall debt — those are already Den-native
policy for this repo.
