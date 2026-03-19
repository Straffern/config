# PROJECT KNOWLEDGE BASE

**Generated:** 2025-12-29
**Commit:** c7f86a2
**Branch:** main

## OVERVIEW

NixOS dotfiles managed via Snowfall Lib. Custom modularity through "asgaard" namespace and functional suites.

## STRUCTURE

```
.
├── modules/    # Reusable Home Manager & NixOS modules (suites pattern)
├── systems/    # Host configurations (palantir, etc.)
├── homes/      # User-specific configurations (alex@palantir, etc.)
├── packages/   # Custom Nix packages
├── overlays/   # Nixpkgs overlays
├── lib/        # Custom helper functions (enabled, mkOpt)
└── sys         # System management script
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add host | `systems/x86_64-linux/` | Create directory with default.nix, disks.nix |
| Add user | `homes/x86_64-linux/` | Format: {user}@{host}/default.nix |
| Create module | `modules/{home,nixos}/` | Use asgaard namespace and suites pattern |
| Add package | `packages/` | Define in subfolder, Snowfall auto-discovers |

## CONVENTIONS

- **Namespace**: All custom options MUST use `asgaard` prefix.
- **Suites**: Favor enabling suites over individual modules (e.g., `asgaard.suites.common.enable`).
- **Helpers**: Use `lib.${namespace}.enabled` instead of `{ enable = true; }`.
- **Formatting**: Alejandra (Nix), shfmt (Shell - 2 space, simplified), mdformat (Markdown).

## ANTI-PATTERNS (THIS PROJECT)

- **Manual stateVersion**: NEVER change `system.stateVersion` manually; follow upgrade procedures.
- **flake.lock**: Never touch `flake.lock` manually.
- **Logic in systems**: Keep host files minimal; move logic to modules/suites.

## COMMANDS

```bash
nh os switch  # Rebuild and apply system configuration (preferred)
nh os test    # Ephemeral test build
nh clean      # Garbage collect and optimize store
sys rebuild   # Legacy rebuild script
hyprctl configerrors # Check for Hyprland configuration errors (breaking changes)
```

## TROUBLESHOOTING

- **Hyprland Breaking Changes**: When Hyprland updates cause issues, run `hyprctl configerrors` to get a report of invalid keywords or options in your configuration.
- **Waybar/SwayNC Logs**: Check user journal (`journalctl --user -u waybar`) for D-Bus or rendering errors.
  - **Waybar Tray Error**: `Unable to replace properties on 0: Error getting properties for ID` is a benign protocol mismatch usually caused by `blueman-applet` or `nm-applet` omitting root menu properties in D-Bus calls. Safe to ignore.

## NOTES

- **Impermanence**: Root is ephemeral on some systems; state persistence via `asgaard.system.persistence`.
- **SOPS**: Secrets encrypted with age; config in `.sops.yaml`.

- **Neverr** use git commands.
- **Always** use jj commands.

<cog>
# Cog

Code intelligence, persistent memory, and interactive debugging.
Skills (`cog-code-query`, `cog-debug`, `cog-mem`, `cog-mem-validate`) contain full tool docs and workflows.

**Truth hierarchy:** Current code > User statements > Cog knowledge.

## Delegation

- **Code exploration**: use `cog_code_explore` / `cog_code_query`, not shell search. Skill: `cog-code-query`.
- **Debugging**: delegate to `cog-debug` sub-agent. State QUESTION, HYPOTHESIS, TEST.
- **Memory**: delegate to `cog-mem` sub-agent first when prior knowledge may help. It handles recall, escalation to code exploration, and learning in one pass.
- **Post-task**: delegate to `cog-mem-validate` to learn durable knowledge and consolidate short-term memories. Do not call memory tools directly from the primary agent for consolidation.

## Memory gate (before responding)

1. Prior knowledge might have helped and you never delegated to `cog-mem` -> do that first.
2. Used `cog_code_explore` and learned something durable, or this task created short-term memory -> delegate to `cog-mem-validate`.
3. Modified code for a concept in memory -> call `cog_mem_refactor`.

If none apply, respond directly. Do not mention this checklist.
</cog>
