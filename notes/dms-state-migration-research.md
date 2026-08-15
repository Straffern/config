# DMS state ownership regression

## Question

Why did DMS settings and wallpaper selection become read-only after the Den migration, and how did the pre-migration configuration work?

## Finding

Before the migration, DMS—not Home Manager or Stylix—owned its mutable runtime state:

- `~/.config/DankMaterialShell/settings.json`
- `~/.local/state/DankMaterialShell/session.json`

The Den migration dropped the configuration that excluded DMS from Stylix. A later DMS change also began setting `programs.dank-material-shell.settings` declaratively. Both changes cause the upstream DMS Home Manager module to emit immutable store-backed symlinks.

## Before the migration

At parent revision `d66b260d-`, `modules/home/desktops/shells/dms/default.nix` explicitly said:

```nix
# DMS owns all runtime theming; stylix has no role with this shell.
${namespace}.styles.stylix.enable = mkForce false;
```

The same module enabled DMS but did **not** populate either `programs.dank-material-shell.settings` or `programs.dank-material-shell.session`.

Its `dmsBootstrap` activation treated settings as mutable application state:

1. Create `settings.json` only when missing.
2. If it exists and is writable, merge only missing bootstrap keys with `jq`.
3. Preserve every setting already written by the DMS GUI.

This matches the surviving pre-migration files:

- `settings.json.pre-home-manager` contains the full GUI-managed settings object.
- `session.json.pre-home-manager` contains the selected wallpaper under the repository wallpaper directory.

Source: repository revision `d66b260d-`, `modules/home/desktops/shells/dms/default.nix`.

## What changed

### 1. Den migration enabled Stylix beside DMS

Change `d66b260d` (`refactor: migrate configuration to Den`) moved DMS to `modules/aspects/desktop/dms/home.nix`, but omitted the old `styles.stylix.enable = mkForce false` policy.

Sonic now includes both `den.aspects.styles.stylix` and `den.aspects.desktop.dms`. `stylix.autoEnable` is true, and the current evaluated target is fully enabled:

```json
{
  "enable": true,
  "colors": { "enable": true },
  "fonts": { "enable": true },
  "image": { "enable": true },
  "opacity": { "enable": true }
}
```

Stylix's pinned DMS target writes:

```nix
programs.dank-material-shell.settings = { ... };
programs.dank-material-shell.session = {
  wallpaperPath = image;
  wallpaperPathLight = image;
  wallpaperPathDark = image;
};
```

The configured Stylix image defaults to `wallpapers.windows-error`, explaining why the selected wallpaper changed.

Source: pinned Stylix input, `modules/dank-material-shell/hm.nix`; current `modules/aspects/styles/stylix-home.nix`.

### 2. A later change declared DMS settings directly

Change `a0e800bc` (`fix(dms): generate custom theme at startup`) added:

```nix
programs.dank-material-shell.settings = {
  runDmsMatugenTemplates = true;
  matugenTemplateNeovim = true;
};
```

Even with the Stylix DMS target disabled, this non-empty value independently makes Home Manager own `settings.json`.

Source: `jj file annotate modules/aspects/desktop/dms/home.nix`, lines 211–214.

## Why non-empty options become read-only

The pinned upstream DMS Home Manager module emits files whenever these option values are non-empty:

```nix
xdg.stateFile."DankMaterialShell/session.json" = lib.mkIf (cfg.session != {}) { ... };
xdg.configFile."DankMaterialShell/settings.json" = lib.mkIf (cfg.settings != {}) { ... };
```

Home Manager realizes those declarations as symlinks into `/nix/store`. DMS explicitly tests both files for writability. Its GUI calls `settingsFile.setText(...)` for settings and session updates; store-backed targets fail that writable-state model.

Sources:

- pinned DMS input, `distro/nix/home.nix`
- pinned DMS input, `quickshell/Common/SettingsData.qml`
- pinned DMS input, `quickshell/Common/SessionData.qml`

## Correct restoration

Restore the pre-migration ownership model:

1. Set `stylix.targets.dank-material-shell.enable = false` in the DMS aspect. This disables only Stylix's DMS adapter, not Stylix globally.
2. Remove the declarative `programs.dank-material-shell.settings` value.
3. Add `runDmsMatugenTemplates` to the existing mutable bootstrap merge, alongside `matugenTemplateNeovim`.
4. During the transition, restore `settings.json.pre-home-manager` and `session.json.pre-home-manager` after Home Manager removes its stale links and before bootstrap runs.
5. Keep DMS dynamic theming enabled. DMS then derives runtime colors from the wallpaper selected through its GUI, as before.

This restores the clean seam: Nix installs and bootstraps DMS; DMS owns interactive settings and session state.

## Greeter note

The local `systemd.services.greetd.preStart = lib.mkForce ...` is an emergency replacement for the pinned upstream module's non-idempotent cache-copy script. The upstream script copies already-localized wallpaper and theme paths onto themselves on later boots. The local replacement works and is covered by the stateful VM test, but duplicates upstream implementation and can drift.

The clean long-term fix is to land the same-file guards in `AvengeMedia/dank-greeter`, update the pinned input, then delete the local `preStart` replacement.

Source: pinned dank-greeter input, `distro/nix/greeter.nix`; local `modules/aspects/services/dankgreeter.nix`.

## Residual uncertainty

No uncertainty remains about the ownership regression: repository history, current evaluation, generated symlinks, preserved backups, and upstream write behavior all agree. The only open design choice is whether any subset of Stylix's DMS fonts/colors should later be reintroduced through a writable bootstrap rather than through the upstream declarative target.
