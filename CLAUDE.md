# NixOS Dotfiles Command Reference & Style Guide

## Build Commands
- Rebuild system: `nh os switch`
- Test config: `nh os test`
- Update flake: `nix flake update`
- Clean store: `nh clean`
- GC settings: Keeps last 3 generations and those from last 4 days

## Code Style Guidelines
- Follow Snowfall lib structure for modules and systems
- Use 2-space indentation in Nix files
- Organize imports alphabetically when possible
- Prefix option names with namespace `asgaard`
- For new modules, copy structure from existing ones
- Keep system configs modular using suites (collections of modules)
- Document non-obvious option declarations with comments
- Use descriptive variable names (camelCase) 
- Prefer explicit imports over `...` pattern

## Git Workflow
- Keep commits focused on single logical changes
- Commit subject should be clear and concise
- Separate configuration and implementation when possible