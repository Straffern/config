# SYSTEMS KNOWLEDGE BASE

## OVERVIEW
Host configurations for NixOS machines (x86_64-linux) and installation ISOs.

## STRUCTURE
- `x86_64-linux/` - Production hosts (grug, palantir, etc.)
- `x86_64-install-iso/` - Custom graphical/minimal install media

## WHERE TO LOOK
- `default.nix` - Main host entrypoint; defines hostname, suites, and user accounts
- `hardware-configuration.nix` - Kernel modules, bootloader, and hardware-specific tweaks
- `disks.nix` / `disko.nix` - Disk partitioning and filesystem layouts
- `facter.json` - Hardware metadata used by `nixos-facter` modules

## ANTI-PATTERNS
- **stateVersion**: NEVER modify `system.stateVersion`; it tracks historical state, not current version
- **Bloated default.nix**: Keep host files lean; move logic to `asgaard` suites/modules
- **Direct Hardware Paths**: Avoid `/dev/sdX` in configs; use UUIDs or labels in disk configs
- **Inline Secrets**: Use `asgaard.security.sops` for all sensitive data; never plain text
