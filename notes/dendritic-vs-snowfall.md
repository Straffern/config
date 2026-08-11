# Dendritic design with flake-parts vs Snowfall Lib

_As of 2026-08-11._

## Short answer

`Doc-Steve/dendritic-design-with-flake-parts` is a guide, not a library or framework. It shows how to apply the Dendritic Pattern using flake-parts. Dendritic organizes code by **feature**: one top-level module can define the NixOS, Home Manager, Darwin, package, and flake-level pieces of that feature. The pattern's canonical description says every non-entry-point file is a top-level module implementing one feature across all applicable configurations ([source](https://github.com/mightyiam/dendritic/blob/main/README.md)).

Snowfall Lib is an opinionated output generator and library. It discovers files through a prescribed directory layout and generates systems, homes, packages, modules, overlays, shells, and other outputs. Its own quickstart describes it as imposing an opinionated file structure ([source](https://snowfall.org/guides/lib/quickstart/)).

They therefore overlap but are not equivalent:

- **Snowfall:** organize primarily by output/configuration class and let naming/layout generate outputs.
- **Dendritic + flake-parts:** organize primarily by feature; modules explicitly contribute typed option values to the flake and lower-level configurations.
- **flake-parts alone:** a minimal module-system representation of flake outputs, not a host/configuration auto-generator ([source](https://github.com/hercules-ci/flake-parts/blob/main/README.md)).

## Is Dendritic better?

In some ways:

- Better locality for cross-cutting features: a feature's NixOS, Home Manager, and Darwin behavior can live together.
- Less dependence on a framework-defined directory schema; paths describe features rather than determine expression type.
- flake-parts provides a small, composable module interface and an active ecosystem rather than Snowfall-specific generators and helpers.
- Automatic importing is possible because files share one top-level module type. The guide uses recursive importing and optionally `vic/import-tree` ([source](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Basics)).

Costs:

- It requires stronger understanding of the Nix module system, module classes, and `deferredModule`; the canonical guide explicitly lists these as required knowledge ([source](https://github.com/mightyiam/dendritic/blob/main/README.md#required-skills)).
- flake-parts does not replace Snowfall's host/home/package discovery. That glue must be expressed as flake-parts modules or supplied by another module.
- Migration changes the architecture, not merely the flake entry point. Existing Snowfall helpers, namespace behavior, and directory-generated outputs must be replaced.

For this dotfiles repository, the strongest reason to migrate is maintenance risk, not missing functionality. The current `flake.nix` uses `snowfall-lib.mkLib`, `lib.mkFlake`, Snowfall namespaces, automatic systems/homes/modules/overlays, and `lib.mkDeploy`; replacing it is a material migration. Dendritic feature locality would be useful if NixOS/Home Manager/Darwin pieces increasingly need to evolve together. Otherwise, the immediate payoff is limited.

## Is it faster?

No defensible apples-to-apples benchmark was found. Do not choose it on a speed claim.

Likely effects, explicitly inference:

- **Build speed:** essentially unchanged when both designs produce the same derivations; these tools mostly affect evaluation and output construction.
- **Evaluation overhead:** flake-parts core is intentionally minimal and describes itself as lightweight ([source](https://github.com/hercules-ci/flake-parts/blob/main/README.md)). Snowfall performs directory discovery and output generation, so a minimal flake-parts configuration can plausibly evaluate with less framework overhead.
- **Dendritic importing:** recursive `import-tree` discovery also performs traversal, so “Dendritic” itself does not guarantee faster evaluation.

Snowfall has a concrete unresolved performance concern: issue [#181](https://github.com/snowfallorg/lib/issues/181) identifies repeated source copying caused by `./.` paths. The issue is closed, but Snowfall's current main `flake.nix` still contains those `./.` paths ([source](https://github.com/snowfallorg/lib/blob/main/flake.nix)). This supports a maintenance/performance concern, not a quantified comparison.

## Is flake-parts more up to date?

Yes, clearly, compared with Snowfall Lib.

- Snowfall's README says it has been “effectively unmaintained for some time” and asks for maintainers ([source](https://github.com/snowfallorg/lib/blob/main/README.md)). Its main flake still pins `nixpkgs/release-23.11` and a fixed `flake-utils-plus` revision ([source](https://github.com/snowfallorg/lib/blob/main/flake.nix)).
- flake-parts had human-authored fixes and module work merged in May 2026, including [`withSystem` fixes](https://github.com/hercules-ci/flake-parts/commit/4604ca55ff5576843b45d0b23465ac902ac74a32), plus ongoing lock maintenance. Its core depends on `nixpkgs.lib` rather than an old full nixpkgs release ([source](https://github.com/hercules-ci/flake-parts/blob/main/flake.nix)).
- Doc-Steve's repository is actively updated, but it is documentation for a pattern; its activity should not be confused with framework maintenance ([repository](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)).

## Recommendation

Do not migrate for speed. Prefer flake-parts for new architecture because it is maintained and composable. For this existing repository, migrate only as a deliberate cleanup away from an unmaintained dependency, ideally host/output type by host/output type while preserving behavior. Dendritic organization is optional: adopt it where feature locality removes real cross-file coordination, not as a mandatory rewrite rule.
