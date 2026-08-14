# Current Den implementation audit

This is a current-state audit, not a migration backlog. It was checked against
this repository and the locked Den input at revision
`e8e8de1e32646456cfc613f152175a7a548508ec`.

Primary references:

- [Core principles](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/core-principles.mdx)
- [Entities and schema](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/entities.mdx)
- [Aspects](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/aspects.mdx)
- [Policies](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/policies.mdx)
- [Class modules](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/class-modules.mdx)
- [Parametric aspects](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/parametric.mdx)
- [Batteries](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/reference/batteries.mdx)
- [Quirks and pipes](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/explanation/quirks-and-pipes.mdx)
- [Design patterns for Dendritic aspects](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Dendritic_Aspects#design-patterns-for-dendritic-aspects) (secondary structural guidance)

## Model used here

Den separates four concerns:

- **Entities** declare what exists and carry typed metadata.
- **Aspects** are selected, composable behavior spanning Nix classes.
- **Policies** define topology, context enrichment, and routing between scopes.
- **Quirks/pipes** aggregate structured data from decoupled producers.

An aspect is not a NixOS-style option namespace and does not need its own
`enable` option. Adding an aspect to an entity's `includes` selects it; removing
the include deselects it. The aspect's `nixos`, `homeManager`, `packages`, or
other class module then uses the native options of that module system. Native
service options such as `programs.nh.enable` remain correct. Likewise,
`host.deployment.enable` is entity metadata controlling deploy-node projection,
not an aspect activation switch.

Registering a policy in `den.policies` does not activate it; policies are
selected through `includes`. An ancestor's `excludes` is authoritative over its
subtree. A repository does not need a custom policy merely to be “more Den”. A
policy is warranted only for an actual topology or routing edge not already
supplied by Den.

## Current implementation

### Entities and schema

- The only entity system is `x86_64-linux`.
- `frostmourne`, `palantir`, and `sonic` are host entities under
  `modules/entities/hosts/`.
- Palantir and Sonic declare Alex with the repository default classes
  `user` and `homeManager`. Frostmourne declares Alex and Niko explicitly as
  `classes = ["user"]`, so both are Den users without Home Manager.
- No `den.homes` entities are declared; Home Manager is intentionally integrated
  into host configurations.
- `modules/aspects/deployment/default.nix` extends `den.schema.host` with typed
  deployment metadata. Concrete values live on each host entity. Deploy output
  generation reads `config.den.hosts` and the canonical `host.hostName`; there is
  no parallel host registry.

This matches Den's distinction between entity facts and aspect behavior.

### Aspects and composition

- `modules/aspects/` is feature-first and concern-owned. Profiles are thin
  include graphs rather than independent host definitions. `profiles.common`
  is a GUI-free host foundation; the cohesive `profiles.desktop` selects both
  system and user desktop concerns. Each concern has one aspect identity, such
  as `styles.fonts`, `styles.stylix`, `desktop.base`, and `desktop.nautilus`,
  with its NixOS and Home Manager behavior expressed as class outputs of that
  aspect rather than separate class-named aspects. Package concerns follow the
  same rule: `styles.monolisa` owns its package and NixOS font payload, while
  `styles.wallpapers` owns its package. Hardware-specific AMD monitoring
  remains a Sonic user provision rather than a generic desktop dependency.
  Gaming core is reusable without compositor or GPU-vendor
  assumptions; Sonic selects AMD graphics directly beside its generic
  Gaming + Niri integration, which composes the canonical gaming profile and
  contributes its Steam Gamescope session through native list merging rather than
  replacing unrelated display sessions. Social composition is limited
  to chat, while the independent photos profile owns Shotwell. Coherent cross-class
  concerns such as Niri and DMS remain unified. Shared Nix tooling does not imply
  a graphics wrapper.
- Host entities select system/profile aspects. Palantir and Sonic use
  `provides.alex` for user-specific additions. In locked Den, an aspect placed
  in a named provider's `includes` is still traversed across its classes in the
  integrated host evaluation. Palantir therefore imports only
  `styles.stylix.homeManager` at its provider module seam; including the whole
  concern there would also select its NixOS payload. This is explicit class
  routing at the call site, not a second class-named aspect identity or a hidden
  membership gate.
- Alex includes `den.batteries.host-aspects`, so user-relevant Home Manager
  classes selected by the host are projected to Alex. Sonic selects the
  cross-class `profiles.desktop` once; Den routes each included aspect's class
  outputs to the appropriate host and user entities.
- Host-local Disko, hardware, facter, and private home fragments remain under
  each entity's `_` directory and are imported by the owning entity/aspect.
  `_` directory presence has no output semantics.
- Packages are computed lexically and passed to native options. Public package
  exposure is explicit in `modules/output-routing.nix`.

Aspects correctly contain native NixOS/Home Manager options. Creating a second
custom option layer merely to configure an aspect would work against this model.

### Policies and routing

The locked Den input supplies and activates the core topology:

- flake → flake-system;
- flake-system → host/home outputs;
- host → declared users;
- class output → flake output.

This repository intentionally changes only package/output routing:

- `system-to-flake-parts` creates the flake-parts entity;
- `packages-to-flake` is authoritatively excluded on the flake-system subtree;
- `packages-to-flake-parts`, a distinct policy rather than an attempted
  re-inclusion of the excluded policy, routes selected package classes into
  per-system flake-parts output;
- the explicit `den.schema.flake-parts.includes` list is the public-output
  allowlist and also activates deployment checks.

No missing custom policy was found. Host/user delivery is already handled by
Den's core host-to-users policy, pipeline-native cross-entity `provides`, and
the `host-aspects` battery. Deployment is a direct projection of host metadata,
not an additional entity relationship.

### Batteries

Global batteries in `modules/defaults.nix` are justified:

- `define-user` creates OS and Home Manager user definitions;
- `hostname` derives hostnames from host entities;
- `inputs'` supplies system-specialized flake inputs to class modules;
- `unfree` limits the global unfree allowlist to named packages.

Alex additionally uses `primary-user`, `host-aspects`, and `user-shell "zsh"`.
The auto-activated `user` class carries Alex's OS-user properties. There is no
local reimplementation of these batteries and no deploy-rs battery in locked
Den.

### Function argument contracts

- Aspect-level parametric functions request pipeline context only. The NH aspect
  uses the exact `{user}:` form; an outer ellipsis is unnecessary.
- Class module functions may mix Den context (`host`, `user`) with module args
  (`config`, `lib`, `pkgs`) and include `...`, as required by Den's flat-form
  wrapper contract.
- Plain module functions that ignore their module argument may use `_:`.
- `host.hasAspect` is a first-party, projected-scope context query used generally
  by persistence contributors. On Sonic, the only impermanent host, affected
  contributors are host-routed and therefore observe impermanence. Palantir
  provides development and OpenCode directly to Alex; they correctly observe
  false because Palantir is not impermanent.
- Conditional module fragments are combined with `lib.mkMerge`, not shallow
  `//`. A shallow union can discard a complete `home` or `environment` subtree
  before the module system sees it. This follows the secondary Dendritic aspect
  pattern guidance and preserves native option merging.
- Den context is not carried through `specialArgs`, `_module.args`, or `den.ctx`;
  none of those legacy context patterns remain.

### Generated root and outputs

`modules/dendritic.nix` imports both flake-file and Den dendritic modules.
Aspect-owned declaration modules own inputs and generator settings. `flake.nix`
is generated, committed, and guarded by
`checks.x86_64-linux.check-flake-file`; it must not be edited directly.

The flake emits the three NixOS configurations, integrated Home Manager state,
the curated package set plus flake-file writer packages, flake-parts checks/dev
shell/formatter, and explicit deploy nodes. It emits no standalone
`homeConfigurations` or additional package family.

`builtins.removeAttrs … ["overlays"]` remains in the generator expression as an
explicit output-contract guard. It is not evidence that an overlay is currently
produced. Removing it would be cleanup only after verifying the generated output
contract and is not required for Den conformity.

## Real remaining gaps

These are bounded current issues, not reasons for speculative framework work:

1. **Concrete-user references in host-only concerns.** Sonic's private NixOS
   fragment, Palantir's private secret paths, and `services.dankgreeter` refer to
   `alex` directly. The private host fragments are consistent with today's
   entity contract. `dankgreeter` is reusable in name but currently assumes
   Sonic's sole Home Manager user. If another user or another DMS host is added,
   model the selected greeter/repository user as typed host metadata or move the
   setting to host-owned configuration. Do not blindly fan a machine-wide option
   out over every user.
2. **NH assumes one relevant user per desktop host.** `platform.nh` uses Den's
   `{user}` fan-out and is correct for Sonic's single user. A future multi-user
   desktop could produce conflicting values for the machine-wide
   `programs.nh.flake`; introduce explicit typed ownership metadata when that
   topology exists.
3. **Named-host predicates remain in two reusable services.** Hermes and
   Hindsight use `host.name == "palantir"` for Palantir-specific behavior. This
   is valid Den context usage and evaluates correctly, but host metadata or a
   host-owned provided aspect would scale better if those roles become dynamic.
4. **Persistence contributions use native options.** Contributors generally test
   projected `host.hasAspect impermanence` and merge native persistence options
   with `lib.mkMerge`. On Sonic, the only impermanent host, affected contributors
   including Social/Discord and OpenCode are host-routed and observe
   impermanence. Palantir provides development and OpenCode directly to Alex;
   they correctly observe false because Palantir is not impermanent. A
   persistence quirk plus pipe would become worthwhile only if multiple backends
   or genuine cross-scope aggregation creates producer/consumer coupling.

## Explicitly deferred or non-issues

- No custom quirk, pipe, namespace, standalone home, Darwin system, or extra
  entity kind is justified by the current fleet.
- More custom policies would add mechanism without adding a missing topology or
  routing edge.
- Small leaf aspects are not inherently Snowfall-shaped debt. Keep a leaf when
  it is an independently selectable concern; consolidate only when selection
  boundaries are demonstrably identical.
- `profiles.video`, `profiles.gamedev`, and their package aspects are attached to
  Sonic. They are not dead configuration.
- Host-local raw NixOS settings are not a second architecture: they are private
  modules owned and imported by a host aspect.
- The fixed `x86_64-linux` deployment projection follows the repository's
  single-system contract; generalization would be speculative.
- Migration has reached the native Den end state: no
  `den.batteries.import-tree` legacy bridge remains.
- No backward-compatibility namespace or additional output abstraction is
  required.
- Development profile decomposition is deferred: its broad workstation bundle
  needs a separate behavior-neutral composition change and host-intent review.
- Tmux's `navi` binding and implicit `sponge` dependency remain a tooling
  cohesion risk to address separately.

## Audit procedure

When revisiting this document:

1. inspect the locked Den revision, not only Den `main`;
2. compare entity declarations, schema extensions, includes/provides, and output
   policies against that source;
3. treat native module options inside aspects as expected;
4. demand a concrete missing relationship before adding a policy;
5. demand multiple decoupled producers or cross-scope aggregation before adding
   quirks/pipes;
6. validate the generated-root staleness check and focused output/entity values;
7. remove resolved findings rather than retaining a historical migration plan.
