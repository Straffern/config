# Domain glossary

NixOS dotfiles for three hosts — `frostmourne`, `palantir`, and `sonic` — on one Den entity system, `x86_64-linux`. Home Manager is host-integrated for Alex on Palantir and Sonic. Frostmourne declares Alex and Niko as home-less Den users.

## Entities and selection

- **host entity** — a `den.hosts.<system>.<name>` record: identity, deployment metadata, VM smoke eligibility, and the host aspect’s `includes` / `provides`.
- **user entity** — a person on a host. Identity aspects own SSH keys and person facts, not runtime groups.
- **aspect** — one concern with class payloads (`nixos`, `homeManager`, `user`, `packages`, `flake-parts`). Selection is `includes`; native NixOS/Home Manager options are the configuration interface.
- **profile** — a thin include-only aspect (`profiles.desktop`, `profiles.development`, …). Profiles do not own class configuration.
- **class** — a module system a payload is written for. Callers include whole aspects; they do not import another aspect’s class payload.
- **policy** — topology or routing. This repository adds none beyond package/output routing already in `modules/output-routing.nix`.
- **quirk / pipe** — structured data collected from selected aspects. `vmSmoke` is the quirk that carries VM probes and their VM-only fixture modules.

## Hosts

- **Sonic** — Framework laptop, graphical Niri and Hyprland sessions with one desktop shell on both (currently Noctalia). Selects `profiles.desktop` and `profiles.development` plus machine-specific concerns. The shell is selected directly: `desktop.noctalia` or `desktop.dms`, never both; each asserts it cannot be selected with `styles.stylix`. No host currently selects Stylix. Discord, Shotwell, Helium, and Slack are direct host includes. Brave, Blender, gamedev, and video application bundles are absent.
- **Palantir** — bare headless VPS dev box, reached over Tailscale with public SSH behind fail2ban. Composes server aspects directly (no `profiles.server`: no avahi, NetworkManager, or remote storage clients; systemd-networkd DHCP). Alex gets `profiles.development-core` and omp; `services.tern-remote` runs a mutable `~/.local/share/tern` install as `tern remote serve --user`, UDP 8376 open on `tailscale0` only. `services.romm` runs RomM + MariaDB in Podman on `127.0.0.1:8080`, published via Tailscale Funnel on `https://palantir.<tailnet>.ts.net:8443`; library at `/var/lib/romm/library/{roms,bios}/<platform>` (uid 1000 = alex).
- **Frostmourne** — k3s node, two home-less users.

## Keys and secrets

- **server key** — `~/.ssh/id_ed25519`, on Sonic only. Logs in to every host (authorized by the `alex` identity aspect) and is the human SOPS identity (`alex_ssh`). It asks for its passphrase on each use: never auto-added to the agent, no SSH control master. It stays registered on GitHub for login and signing, but ssh offers only the GitHub key there (`IdentitiesOnly`) and git signs with the GitHub key.
- **GitHub key** — `~/.ssh/github`, passphrase-protected, on Sonic only. GitHub login and commit signing. `ssh-unlock`, or the first GitHub connection from a terminal (`AddKeysToAgent yes`), loads it into Sonic's agent once per login; the agent keeps identities without a lifetime, so forwarded hosts can use it. Until then agents can't reach GitHub or sign, `git commit` asks for the passphrase per commit, and `jj git push` fails.
- **Palantir's agent** — Palantir holds no private user key. Login shells, tmux and user services use `~/.ssh/agent.sock`; `~/.ssh/rc` points it at each terminal login's forwarded agent (logins without a tty leave it), so panes and agents survive reconnects but reach GitHub only while Alex is connected. `~/.ssh/github.pub` is Home Manager-managed so ssh (`IdentitiesOnly`) and git pick the key from the agent. Palantir runs no ssh-agent of its own.
- **signing** — on by default everywhere, with the GitHub key from the agent, so agents sign too: a signature means "from Alex's machines", not "typed by Alex". `git commit` signs; jj signs your unsigned commits at `jj git push` (`git.sign-on-push`, `behavior = "drop"`), so local jj commits on Palantir work without an agent. `git commit --no-gpg-sign` is the escape hatch there.
- **host secrets** — `secrets/hosts/*.yaml` and `secrets/suites/*.yaml`, encrypted to the host key and the server key only.
- **home secrets** — `secrets/homes/<host>.yaml`, decrypted by Home Manager at login with the passphrase-free `~/.config/sops/age/home-manager.txt`. They hold only values the user's processes read anyway; anything root-only belongs in host secrets.

## Mutable sources and desktop shells

- `mutable on|off|status` switches Neovim Lua, AI-harness instructions, and Noctalia's config, Settings overrides, and compositor fragments between the integrated Home Manager generation's store files and links into `~/.dotfiles`. The mode flag lives under XDG state; the Home Manager system service restores the mutable child after a rebuild.
- The Hyprland `hyprland.lua` entry config links to the repo and requires `hypr/shell.lua`, which the selected shell aspect provides. Under Niri, the shell aspect owns `niri/config.kdl` and includes Home Manager's `niri/hm.kdl`.
- DMS owns writable compositor fragments under `niri/dms/` and `hypr/dms/`; its entry fragments always link to repo files. DMS starts under `graphical-session.target` only when the desktop is Niri or Hyprland, not gamescope; Noctalia follows the same rule.
- Noctalia renders terminal, GTK/Qt, and compositor colors through templates whose outputs Home Manager configs include. Noctalia Greeter preselects Hyprland when the host includes it.

## VM smoke

- **eligibility** — host-schema fields: `enable`, `skipReason`, `loginUser`, `sessionCommand`, resources, `allowedKernelErrors`.
- **host override** — a VM-only adapter that is truly host-private (for example Sonic’s virtio-gpu vs physical AMD).
- **aspect fixture** — a `vmSmoke` descriptor `module` owned by the aspect under test. Descriptor modules may read `vmSmoke` from NixOS `specialArgs` (the typed session contract: `loginUser`, `sessionCommand`, …).
- **producer** — `tooling.vm-smoke` maps eligible hosts to `checks.vm-smoke-<host>`. Instantiation still reuses the generated NixOS module list because `host.mainModule` omits Den’s host-instantiation effects (integrated Home Manager).

## Outputs

- **public packages** — the `packages` class of aspects included by `outputs.public-packages`. That aspect is the allowlist; `packages-to-flake-parts` consumes it. Tooling/check aspects stay on `den.schema.flake-parts.includes` beside it.
- **deployment** — host-schema `deployment.*` projected to `flake.deploy.nodes` for every host system that has enabled nodes. Palantir and Frostmourne are the remote deploy targets; Sonic may still declare a node.