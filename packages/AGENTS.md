# 📦 Packages

## OVERVIEW
Custom Nix package definitions auto-discovered by Snowfall Lib.

## STRUCTURE
- `packages/{name}/default.nix`: Package definition
- `packages/{name}/...`: Supporting files (patches, assets)

## CONVENTIONS
- **Snowfall Discovery**: Folders automatically exported to `pkgs.asgaard.{name}`.
- **CallPackage**: Always use functional pattern `{ stdenv, ... }:` in `default.nix`.
- **Simple Tools**: Use `writeShellScriptBin` for shell wrappers (see `packages/sys`).
- **Discovery**: No manual `flake.nix` wiring required.

## WHERE TO LOOK
| Type | Folder | Note |
|------|--------|------|
| Shell Scripts | `sys/`, `ai-shell/` | Wrapper scripts (sys is legacy) |
| Binary Apps | `huenicorn/`, `cass/` | Compiled applications |
| Assets | `wallpapers/`, `monolisa/` | Static data and fonts |

## ANTI-PATTERNS
- **Manual Wiring**: Never add packages to `flake.nix` manually.
- **Relative Imports**: Avoid `../` to reference other packages; use `pkgs.asgaard.{name}`.
- **Absolute Paths**: Always use Nix store paths.

## MAINTENANCE
- **Updating SRIs**: Use `nix-prefetch-url` or `nix hash to-sri` for `sha256`.
- **Testing**: Run `nix build .#packages.x86_64-linux.{name}` to verify builds.
- **Debugging**: Check `result/` symlink for build output.

