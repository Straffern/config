# Den-driven per-host NixOS VM smoke tests

Status: feasible. Recommended design: host schema controls eligibility/VM exceptions; Den quirks let selected aspects contribute smoke assertions; one flake-parts producer maps eligible `den.hosts` to `checks.vm-smoke-<host>`.

## Evidence base

- Repository lock: `flake.lock`, node `den.locked.rev = e8e8de1e32646456cfc613f152175a7a548508ec`; node `nixpkgs.locked.rev = 4382ed2b7a6839d4280a9b386db49cbc5907414d`.
- Locked Den references below mean `github:denful/den/e8e8de1e32646456cfc613f152175a7a548508ec/<path>`.
- Repository references are local paths in this checkout.

## Findings

### 1. Host/entity metadata and defaults are first-class Den schema extensions

`den.hosts.<system>.<name>` is a non-strict/freeform schema instance. Arbitrary metadata works without declaration, but `den.schema.host` is the correct typed/defaulted extension point. The schema module may declare options and defaults and receives `host`, `lib`, etc. `den.schema.conf` applies to host/user/home; `den.schema.user` and `den.schema.home` provide kind-specific defaults. Schema entries also have pipeline-owned `includes`/`excludes`. Adding a `den.schema.<kind>` key registers another entity/routing kind.

Exact sources:

- `docs/src/content/docs/reference/schema.mdx`, headings **Schema Base Modules**, **den.schema**, **Entity Kinds**, **den.hosts**.
- `modules/options.nix`, `options.den.schema = schemaLib.mkSchemaOption`, built-in `user.parent = "host"`, `home.parent = "host"`, and `den.schema.{conf,fleet,host,user,home}` configuration.
- `nix/lib/entities/host.nix`, `hostType = schemaLib.mkInstanceType den.schema.host { strict = false; ... }`; built-ins include `class`, `system`, `mainModule`, `users`, and `instantiate`.
- Repository precedent: `modules/aspects/deployment/default.nix` declares typed `den.schema.host.options.deployment`, filters `config.den.hosts.${system}`, and derives deploy outputs rather than maintaining a second host list.

**Conclusion:** define VM policy in `den.schema.host`; do not add parallel per-host VM declarations.

### 2. Selected aspects can contribute descriptors automatically

Den aspects support registered quirks: structured/raw data keys collected through the same resolution pipeline as class modules. Any selected/included aspect may emit a quirk value; list values flatten; a class module can request the quirk argument and receives the current scope's collected values. This exactly models “a service aspect contributes its own smoke assertion.”

Exact sources:

- `docs/src/content/docs/reference/quirks.mdx`, headings **den.quirks**, **Producing quirk data**, **Consuming quirk data**, **pipe.expose**, and **Assembly**.
- `modules/options.nix`, `options.den.quirks` and its class-name collision assertion.
- `docs/src/content/docs/reference/aspects.mdx`, **Aspect structure**, **Static vs parametric includes**, and **Class resolution**.
- `modules/aspects/defaults.nix`: `den.default` is injected into every host/user/home schema include, showing automatic schema-level activation.

Recommended declaration:

```nix
den.quirks.vmSmoke.description = "NixOS VM smoke-test descriptors";

# In any host-selected aspect:
den.aspects.services.example.vmSmoke = [
  {
    name = "example-ready";
    script = ''machine.wait_for_unit("example.service")'';
  }
];
```

Add one always-selected host collector aspect. Its `nixos = args@{ lib, ... }: ...` reads `args.vmSmoke`, validates descriptor names, and publishes them under a private typed NixOS option such as `asgaard.vmSmoke.descriptors`. This keeps raw quirk data out of the generator and lets the evaluated test node expose the final merged descriptors.

**Caveat:** quirk delivery is scope-local. A quirk emitted by an aspect selected in a nested user/Home Manager scope is not automatically host data. If HM/user aspects must contribute host assertions, install an explicit user-scope pipe policy using `pipe.from "vmSmoke" [ pipe.expose ]`; otherwise document that VM descriptors belong to host-selected aspects. `pipe.expose` is the locked Den mechanism for child-to-parent flow.

### 3. Generate one check per eligible host; reuse `host.mainModule`

A flake-parts aspect can map the evaluated host registry directly. This repository already uses that pattern in `modules/aspects/deployment/default.nix`: it filters `config.den.hosts.x86_64-linux` and contributes `checks` from a `flake-parts` class. Den resolves the flake-parts class into `perSystem`.

Exact sources:

- `modules/outputs.nix`: `perSystem.imports = [ (den.lib.aspects.resolve "flake-parts" (den.lib.resolveEntity "flake-parts" { })) ]`.
- `modules/context/flake-schema.nix`: registers `flake`, `flake-system`, and `flake-parts` routing kinds.
- `templates/flake-parts-modules/modules/den.nix`: selects a flake-parts aspect with `den.schema.flake-parts.includes`.
- `templates/flake-parts-modules/modules/perSystem-from-hosts.nix`: demonstrates programmatic traversal of all `den.hosts` with `resolve.to "host"`.
- Repository: `modules/aspects/deployment/default.nix`, `den.aspects.deployment.flake-parts = { system, ... }: { checks = ...; };`.
- Locked nixpkgs `nixos/lib/testing-python.nix`: public `runTest` path and test attributes (`nodes`, `testScript`, `globalTimeout`); it explicitly directs callers away from legacy `specialArgs` toward `node.specialArgs`.
- Locked nixpkgs `nixos/tests/boot.nix`: primary example of a boot smoke test using `machine.start()`, `machine.wait_for_unit("multi-user.target")`, assertions, and shutdown.

Architecture:

1. At top-level module evaluation, flatten `config.den.hosts.${system}` and retain `host.class == "nixos" && host.vmSmoke.mode != "skip"`.
2. Select the producer explicitly with `den.schema.flake-parts.includes = [ den.aspects.vm-smoke-checks ];`.
3. In `den.aspects.vm-smoke-checks.flake-parts`, use `pkgs.testers.runNixOSTest`/the current public `runTest` interface once per retained host.
4. Set `nodes.machine.imports = [ host.mainModule commonVmOverrides ] ++ host.vmSmoke.modules`. `mainModule` is Den's resolved source module (`nix/lib/entities/host.nix`), so the VM follows the exact entity/aspect/policy selection without manually reconstructing or importing an already-instantiated `config` attrset.
5. Use a function-valued `testScript` if needed to read `nodes.machine.config.asgaard.vmSmoke.descriptors`; prepend baseline boot readiness, append descriptor scripts, then shut down.
6. Emit `checks."vm-smoke-${name}"`; use `lib.mapAttrs'`/`lib.listToAttrs`, asserting unique output names.

Do not import `nixosConfigurations.<host>.config` as a module. Reusing `host.mainModule` is the cleaner Den-owned authoring boundary and permits test-only modules in the same evaluation.

### 4. Concrete host schema

```nix
den.schema.host = { lib, ... }: {
  options.vmSmoke = {
    mode = lib.mkOption {
      type = lib.types.enum [ "boot" "build" "skip" ];
      default = "boot";
      description = "Runtime boot test, VM build-only check, or explicit exclusion.";
    };
    skipReason = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    waitForUnit = lib.mkOption {
      type = lib.types.str;
      default = "multi-user.target";
    };
    timeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 900;
    };
    memorySize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2048;
    };
    cores = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
    };
    modules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
      description = "Test-only compatibility overrides; never production config.";
    };
  };
};
```

Descriptor convention:

```nix
{
  name = "unique-kebab-name";
  script = ''machine.succeed("command")''; # Python test-driver fragment
}
```

Keep descriptors minimal (`name`, `script`). Add fields only when a demonstrated consumer exists. Assert globally unique descriptor names per host and require non-empty `skipReason` for `mode = "skip"`. `build` should still build the generated VM derivation but not claim a boot/runtime result.

## Host and integration caveats

- **[high] Physical disk/boot configuration can make the VM non-bootable.** All three host aspects import hardware/Disko modules: `modules/entities/hosts/{frostmourne,palantir,sonic}/default.nix`. Frostmourne additionally forces GRUB/EFI settings in `modules/entities/hosts/frostmourne/_/nixos.nix`; Sonic sets resume device, filesystem/kernel constraints in `modules/entities/hosts/sonic/_/nixos.nix`. Supply common test-only `lib.mkForce` overrides for bootloader, root/swap/resume, hardware-only services, and mounts; use host `vmSmoke.modules` only for remaining exceptions.
- **[high] Secrets and machine-bound activation may evaluate but fail at boot.** SOPS/age, impermanence, WireGuard, hardware/facter, and remote filesystems may need placeholder/test credentials, disabled units, or `mode = "build"`. Never expose production secrets in descriptors or test modules.
- **[medium] “Build” is not “boot.”** Report modes distinctly; a VM derivation build only proves evaluation/build closure.
- **[medium] Assertions from user/HM aspects require scope routing.** Use `pipe.expose`, or constrain contributions to host-selected aspects.
- **[medium] Integrated Home Manager is part of the NixOS node.** Locked Den `docs/src/content/docs/guides/home-manager.mdx`, **How it Works**, says the host policy imports the HM OS module and forwards each enabled user's `homeManager` class into `home-manager.users.<name>`. Therefore the VM evaluates/builds integrated HM for Palantir/Sonic automatically; no standalone `homeConfigurations` check should be created. Frostmourne users explicitly have only `[ "user" ]` in `modules/entities/hosts/frostmourne/default.nix`, so no HM output/test should be assumed.
- **[medium] Host-scope `{ user, ... }` content does not target HM.** The locked HM guide explicitly states host-scope parametric aspects no longer deliver Home Manager content to users; use the existing `provides.alex`/policy routing or an explicit user pipe.
- **[low] System filtering matters.** The repository contract is currently only `x86_64-linux`, but generator logic should still use the current flake-parts `system` and require `host.class == "nixos"` rather than hard-coding names.

## Recommended placement

Follow the repository's concern-owned aspect convention:

- one new VM-smoke aspect module beside `modules/aspects/deployment/default.nix`;
- schema, quirk, collector, flake-parts check producer, and common VM overrides colocated there or in its `_` directory;
- only exceptional host metadata in `modules/entities/hosts/<host>/default.nix`.

No generated-root edit. `flake.nix` is generated and must remain untouched.

## Validation plan

1. `nix eval --json .#checks.x86_64-linux --apply builtins.attrNames` — verify exactly one generated name per non-skipped eligible host.
2. `nix build .#checks.x86_64-linux.vm-smoke-<host> -L` — validate each mode; initially run hosts individually.
3. `nix flake check -L` after all host exceptions are explicit.
4. `nix run .#write-flake` twice and verify no generated-root drift if inputs/modules changed.

## Residual uncertainty

No test was executed in this research-only task. Exact test-driver option names for memory/cores and the minimum force-overrides needed by each hardware/Disko module must be confirmed against the locked nixpkgs test module during implementation. The Den mechanism and output-generation architecture are supported directly by the pinned sources above.

## Implementation correction

Importing `host.mainModule` alone omitted modules added by Den's host-instantiation effect, including the integrated Home Manager bridge. Palantir then rejected valid Home Manager Stylix options. The generic producer therefore reuses each generated `nixosConfigurations.<host>._module.args.modules` list. This remains host-generic and mirrors the instantiated production configuration exactly, but relies on the NixOS configuration's internal module list until Den exposes the complete instantiated module set through a public interface.