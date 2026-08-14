# Den aspect class routing

Research target: Den `e8e8de1e32646456cfc613f152175a7a548508ec`, which was also upstream `main` at retrieval time. All GitHub links below are pinned to that revision.

## Evidence

- An aspect is one cross-cutting concern with modules for multiple Nix classes. The guide's canonical shape is `gaming = { nixos = ...; homeManager = ...; ...; }`: [`configure-aspects.mdx:18-26`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/guides/configure-aspects.mdx#L18-L26).
- `includes` selects another aspect's **full DAG**, and the guide composes whole aspect references: [`configure-aspects.mdx:116-139`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/guides/configure-aspects.mdx#L116-L139).
- Host-scope `homeManager` content is class-local and inert unless routed to a user: [`home-manager.mdx:240-250`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/docs/src/content/docs/guides/home-manager.mdx#L240-L250). The first-party regression covers plain and parametric host aspects: [`issue-609-host-scope-hm-leak.nix`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/templates/ci/modules/deadbugs/issue-609-host-scope-hm-leak.nix).
- The `host-aspects` battery explicitly projects only `user.classes` from the host DAG. Its source says host `homeManager` is forwarded while host classes such as `nixos` are ignored: [`host-aspects.nix:3-24`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/modules/aspects/batteries/host-aspects.nix#L3-L24). Its first-party tests cover Home Manager projection, opt-in, and absence of NixOS duplication: [`public-api/host-aspects.nix`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/templates/ci/modules/public-api/host-aspects.nix).
- Named `provides.<entity>` is entity filtering, not an HM-only class view. The cross-policy includes the provided aspect after matching the entity name: [`provide.nix:29-51`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/nix/lib/aspects/fx/aspect/provide.nix#L29-L51). User-scoped NixOS configuration intentionally fans into the host: [`user-scoped-host-class-fanout.nix`](https://github.com/denful/den/blob/e8e8de1e32646456cfc613f152175a7a548508ec/templates/ci/modules/features/user-scoped-host-class-fanout.nix).
- A survey of the pinned guides, tutorials, templates, and public tests found no composition example that surgically imports `den.aspects.<concern>.nixos` or `.homeManager`. Class-qualified paths in examples define an aspect's owned class payload; composition uses whole aspects.

## Repository conclusions

### Zsh

`cli.zsh` is one cross-class concern and `profiles.common` selects it whole. On Frostmourne its Home Manager payload has no target: Alex and Niko have only `classes = ["user"]`. On Palantir and Sonic, Alex opts into `host-aspects`, so Den projects the host DAG's Home Manager class to Alex. This is the routing Den documents; direct `.nixos` and `.homeManager` imports were unnecessary.

Importing the NixOS or Home Manager Zsh module only defines its options. The repository's respective `programs.zsh.enable = true` values activate Zsh in each resolved class; Alex's login-shell selection remains the separate `user-shell "zsh"` battery.

### Podman

The current fleet wants the Podman runtime and clients together on both relevant hosts. `profiles.desktop` selects the whole concern for Sonic; Palantir selects the whole concern at host scope. Alex receives its Home Manager clients through `host-aspects`. Development no longer dissects the aspect by class.

If a real client-only consumer appears later, runtime and client are separate selection intents and should become explicitly named concern aspects (optionally composed by a whole aggregate). The solution should not import another aspect's class payload directly.

### Stylix and icons

Palantir now selects the complete `styles.stylix` and `styles.icons` concerns at host scope, matching Sonic's whole-aspect composition. This intentionally enables both Palantir system Stylix and Alex's projected Home Manager Stylix; Alex retains the Palantir Dracula override. `styles.icons` enables GTK and installs the configured Catppuccin Papirus package through `gtk.iconTheme`, so it no longer relies on Stylix to activate GTK or installs unrelated Tela packages.
