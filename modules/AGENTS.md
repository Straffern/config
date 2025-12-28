# 🧩 Modules Knowledge Base

## OVERVIEW
Core configuration logic for NixOS (system) and Home Manager (user) via Snowfall Lib.

## STRUCTURE
- `nixos/`: System-wide settings (boot, hardware, services, security).
- `home/`: User-specific environment (apps, shell, desktop, themes).
- **Sub-Categories**:
  - `cli/`: Shells, editors, multiplexers, terminal emulators.
  - `suites/`: High-level entry points (bundles related modules).
  - `styles/`: Theming via Stylix (Catppuccin Macchiato).
  - `system/`: Core OS/User logic (persistence, nix settings, mutable files).

## WHERE TO LOOK
| Task | Location |
|------|----------|
| New System Feature | `modules/nixos/{category}/` |
| New App Config | `modules/home/cli/programs/` or `modules/home/programs/` |
| Grouping Modules | `modules/{nixos,home}/suites/` |
| Hardware Tweak | `modules/nixos/hardware/` |
| Secrets Config | `modules/{nixos,home}/security/sops/` |

## CONVENTIONS
- **Namespace**: `asgaard` (e.g., `asgaard.suites.common.enable`).
- **Logic**: Use `lib.${namespace}.enabled` helper for clean toggles.
- **Modularity**: Small, single-purpose modules.
- **Suites**: Hosts/Users should primarily enable suites, not individual modules.
- **Persistence**: Managed via `asgaard.system.persistence` in both NixOS and Home levels.

## ANTI-PATTERNS
- Hardcoding user paths (use `config.home.homeDirectory`).
- Adding packages to `suites` (create a module or add to `user/default.nix` if specific).
- Mixing Home Manager logic in NixOS modules (keep them strictly separated).
