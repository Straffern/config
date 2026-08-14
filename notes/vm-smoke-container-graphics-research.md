# Research: NixOS test containers and deterministic Niri graphics

## Summary

The repository's locked nixpkgs supports first-class `systemd-nspawn` test machines through `containers.<name>`, including mixed QEMU/container tests. Containers are useful for the repository's command-only and ordinary system/user-service probes, but they cannot replace the Sonic graphical path: they share the host kernel, lack a private VT/DRM device model, do not support the QEMU console input API used by the login probe, and cannot validate a real Niri/logind/DRM session.

For deterministic Niri coverage without a host GPU, retain QEMU and explicitly provide a virtual display. The lowest-risk current configuration is `virtio-gpu-pci` plus Mesa software rendering; VirGL is faster but depends on host GL/GPU access. VKMS is deterministic KMS but is not a renderer by itself. Niri's internal headless backend is test-only and is not exposed by the shipped CLI.

## Findings

### 1. Current nixpkgs test-framework support

1. **Supported now, including in the repository lock.** Root `flake.lock` resolves nixpkgs to `9f78f44a87948854445dae0b6bf82b2e87e4efb5`. At that revision the test module accepts both `nodes` (QEMU) and `containers` (nspawn); `defaults`, `nodeDefaults`, and `containerDefaults` support shared or backend-specific configuration. The generated driver configuration has separate VM and container maps. [Pinned test manual](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/doc/manual/development/writing-nixos-tests.section.md) [Pinned test network module](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/lib/testing/network.nix)

2. **Host configuration is materially different.** Container tests require Nix `auto-allocate-uids` and `cgroups`, plus the `uid-range` system feature. Mixed VM/container VLAN tests additionally require `/dev/net` in `sandbox-paths`. The current runner does not request these; changing `nodes.machine` to `containers.machine` alone is insufficient. [Pinned running-tests manual](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/doc/manual/development/running-nixos-tests.section.md) [Pinned `run.nix`](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/lib/testing/run.nix)

3. **Trade-off is process/OS fidelity versus machine fidelity.** The official manual says containers start faster, consume fewer resources, work better inside virtualized CI, and can bind host device nodes. VMs provide a separate kernel, graphical/X11 testing, systemd namespace/hardening options such as `ProtectSystem=`/`MountAPIVFS=`, specialisations, and SUID/SGID wrappers. nspawn is a namespace container that can boot a full userspace, but it still shares the host kernel. [Pinned test manual](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/doc/manual/development/writing-nixos-tests.section.md) [systemd-nspawn manual](https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html)

4. **Severity: high — the existing runner is QEMU-specific.** [`modules/aspects/tooling/vm-smoke/default.nix`](../../modules/aspects/tooling/vm-smoke/default.nix) defines only `nodes.machine`, sets QEMU-only `virtualisation.{cores,diskSize,graphics,memorySize,writableStoreUseTmpfs}`, sends console keys, checks the guest kernel journal, and shuts down a VM. A container variant needs a separate backend branch, `containers.machine`, backend-specific defaults, and backend-appropriate health checks; it should not silently reinterpret the existing check.

### 2. Which repository probes meaningfully fit containers

| Probe/path | Container value | Qualification |
|---|---|---|
| `neovim` — [`modules/aspects/cli/neovim/default.nix`](../../modules/aspects/cli/neovim/default.nix) | **High** | Pure headless command/config closure check. |
| `dms-theme` — [`modules/aspects/desktop/dms/nixos.nix`](../../modules/aspects/desktop/dms/nixos.nix) | **High** | File-generation check, if Home Manager activation/user manager is started independently of a graphical session. |
| `tmux` — [`modules/aspects/cli/tmux.nix`](../../modules/aspects/cli/tmux.nix) | **High** | User service and socket/session reachability; no hardware dependency. |
| `pipewire` — [`modules/aspects/hardware/audio.nix`](../../modules/aspects/hardware/audio.nix) | **Medium-high** | Meaningfully tests user units, PipeWire core, Pulse compatibility, WirePlumber, `pw-cli`, and `wpctl`; does **not** test ALSA/Bluetooth/RAOP hardware, realtime scheduling quality, or audio transport. |
| `desktop-portal` — [`modules/aspects/desktop/addons/xdg/default.nix`](../../modules/aspects/desktop/addons/xdg/default.nix) | **Medium** | Tests D-Bus activation/name ownership only. Without a compositor/session environment it does not validate GTK/GNOME UI, ScreenCast, Screenshot, or PipeWire stream negotiation. |
| `dms` — [`modules/aspects/desktop/dms/nixos.nix`](../../modules/aspects/desktop/dms/nixos.nix) | **Low-medium** | Service-liveness only may run with a synthetic Wayland display; the actual shell/rendering path is graphical and should remain VM coverage. |
| `palantir-dashboard` — [`modules/aspects/services/hermes/palantir-dashboard.nix`](../../modules/aspects/services/hermes/palantir-dashboard.nix) | **Medium** | HTTP behavior is container-suitable, but this unit uses `DynamicUser`, `PrivateTmp`, `ProtectSystem=strict`, and `ProtectHome`; nixpkgs explicitly identifies systemd namespacing/hardening as VM-only in sandboxed nspawn. It needs a container-only hardening override, which weakens module fidelity. |
| `k3s` — [`modules/aspects/services/k3s.nix`](../../modules/aspects/services/k3s.nix) | **Low-medium** | API readiness is useful, but k3s exercises cgroups, mounts, networking, iptables, and host kernel features. It requires explicit nesting/capability/device/network work and ceases to validate the declared kernel. Keep VM as authoritative. |
| `dank-greeter` — [`modules/aspects/services/dankgreeter.nix`](../../modules/aspects/services/dankgreeter.nix) | **Low** | `greetd.service` process liveness alone is possible; `dms-greeter` rendering is not. |
| `graphical-login` — same file | **No** | Uses `send_chars`/`send_key` against tty2 and validates a seat login. nspawn has no emulated keyboard/VT console path in the NixOS driver. |
| `niri` — [`modules/aspects/desktop/niri/nixos.nix`](../../modules/aspects/desktop/niri/nixos.nix) | **No as written** | `niri-session` deliberately selects the TTY backend, which needs session/seat/DRM devices. Process-only nested Niri would test a different path. |
| baseline failed system/user units | **High/medium** | Useful, but container-incompatible hardening units must be explicitly classified rather than globally ignored. |
| baseline kernel errors | **No** | Containers share the host kernel and do not boot the configured guest kernel. A quiet container kernel journal is not evidence about the NixOS kernel/module configuration. |
| baseline coredumps | **High** | Useful for container processes if coredump collection is actually enabled and visible inside the container. |

A practical split is therefore: keep one authoritative VM smoke per host; optionally add a fast container lane for Neovim, tmux, theme generation, PipeWire control-plane, basic portal D-Bus ownership, and uncomplicated HTTP/system services. Do not call that lane a replacement for the current VM smoke.

### 3. Desktop-session components in nspawn/NixOS containers

1. **greetd and PAM can create a user session, but a real graphical seat is the missing contract.** `pam_systemd` registers sessions and starts `user@.service`; logind tracks sessions with or without seats. However, local graphical sessions depend on a seat, VT, and device ACLs, and logind grants/revokes seat device access for active sessions. Thus a container can test authentication/PAM/user-manager mechanics, but not faithfully test greetd switching tty2 or acquiring the graphical seat. [pam_systemd](https://www.freedesktop.org/software/systemd/man/latest/pam_systemd.html) [sd-login](https://www.freedesktop.org/software/systemd/man/latest/sd-login.html) [systemd-logind](https://www.freedesktop.org/software/systemd/man/latest/systemd-logind.html)

2. **Niri/Wayland is possible only as a deliberately different nested or device-passthrough experiment.** A container has no private DRM/KMS hardware. Binding host `/dev/dri` would test the host kernel/driver and creates ownership/seat conflicts; it is not deterministic or sandbox-portable. A nested Niri can run when `WAYLAND_DISPLAY`/`DISPLAY` exists because Niri selects its winit backend, but `niri --session` removes those variables and selects TTY except on WSL. The repository uses `niri-session`, so this is not equivalent coverage. [Pinned Niri `main.rs`](https://github.com/YaLTeR/niri/blob/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6/src/main.rs) [Pinned Niri backend selection](https://github.com/YaLTeR/niri/blob/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6/src/niri.rs)

3. **DRM outputs cannot be container-created independently.** DRM/KMS devices and kernel modules belong to the shared host kernel. nspawn can bind an existing host device, but cannot provide a guest-only deterministic connector. Consequently DRM output enumeration, modesetting, VT switching, logind `TakeDevice`, and Niri's TTY backend belong in a VM. VKMS loaded “inside” a container is actually a host-kernel module and affects the host. [VKMS kernel documentation](https://docs.kernel.org/gpu/vkms.html)

4. **PipeWire is container-testable at the daemon/control-plane level.** PipeWire is Unix-socket client/server software and even provides `pw-container` security-context support. Running a private PipeWire/WirePlumber graph inside the nspawn guest is meaningful. Passing a host PipeWire socket instead tests cross-namespace plumbing, not the declared NixOS audio stack. [PipeWire native protocol](https://pipewire.pages.freedesktop.org/pipewire/page_native_protocol.html) [pw-container](https://pipewire.pages.freedesktop.org/pipewire/page_man_pw-container_1.html)

5. **Portals divide into non-graphical D-Bus coverage and graphical portal coverage.** Name ownership, backend selection files, and some non-UI calls can run in a container. File chooser, Screenshot, ScreenCast, parent-window handling, and PipeWire stream authorization require a functional desktop session/compositor. PipeWire's portal design passes a restricted connection FD from the portal to a sandboxed client; service liveness alone does not exercise it. Niri upstream requires session mode plus GTK/GNOME portals and specifically uses GNOME for screencasting. [PipeWire portal access](https://pipewire.pages.freedesktop.org/pipewire/page_portal.html) [Niri Important Software](https://niri-wm.github.io/niri/Important-Software.html)

6. **Graphical rendering in a container is technically possible but not supported by the NixOS container test backend as graphical-machine testing.** It needs either passed host render/display nodes and sockets, or an all-software nested stack. Neither supplies the driver's QEMU framebuffer, keyboard injection, OCR, or screenshots, and neither validates the real TTY/KMS path. Use such a test only as a targeted Wayland protocol/client test.

### 4. Deterministic Niri outputs in QEMU/NixOS tests

1. **Severity: high — `graphics = true` is not a GPU selection.** In pinned nixpkgs, `virtualisation.graphics` only controls whether QEMU uses a graphics window versus `-nographic` and console preference. The current Sonic setting therefore does not promise a Niri-compatible DRM device. Add explicit QEMU device options. [Pinned `qemu-vm.nix`](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/modules/virtualisation/qemu-vm.nix) [`modules/entities/hosts/sonic/default.nix`](../../modules/entities/hosts/sonic/default.nix)

2. **Recommended baseline: 2D virtio-gpu + guest Mesa software renderer.** Use `virtualisation.qemu.options = [ "-vga none" "-device virtio-gpu-pci" ];` (or the equivalent single option string accepted by the module). This yields a deterministic virtual KMS connector without requiring host GPU acceleration; QEMU documents that its 2D backend expects guest software rendering and that Mesa llvmpipe/lavapipe work on typical Linux guests. nixpkgs' own Cage and Sway tests use `-vga none -device virtio-gpu-pci` because the default VGA is unsuitable for Wayland compositors. [QEMU virtio-gpu](https://www.qemu.org/docs/master/system/devices/virtio/virtio-gpu.html) [nixpkgs Cage test](https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/cage.nix) [nixpkgs Sway test](https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/sway.nix)

   Validate this path explicitly: wait for a connected output via `niri msg --json outputs`, require a current mode, run a simple SHM Wayland client, and take a test-driver screenshot. Do not merely assert `niri.service` and Xwayland process liveness.

3. **VirGL/virtio-gpu-gl is optional acceleration, not the deterministic default.** `virtio-gpu-gl-pci`/`virtio-vga-gl` plus a GL-enabled QEMU display gives the guest virgl rendering, but QEMU must access host GL/GPU resources and share graphics memory. This contradicts the “without host GPU access” requirement and often fails in headless/sandboxed builders. Use only for a separately tagged acceleration test. [QEMU virtio-gpu](https://www.qemu.org/docs/master/system/devices/virtio/virtio-gpu.html)

4. **VKMS is useful but incomplete alone.** Kernel VKMS supplies a software-only KMS display intended for headless testing. It does not itself supply Niri's EGL/GLES renderer. In a VM it can be loaded safely and deterministically, but Niri must still have a compatible render node (for example virtio-gpu/Mesa), and multi-device render/scanout behavior adds complexity. Prefer plain virtio-gpu first; use VKMS when the test specifically needs controllable virtual KMS/writeback behavior. Never use host VKMS through a container for an isolated NixOS test. [VKMS kernel documentation](https://docs.kernel.org/gpu/vkms.html)

5. **Niri's headless backend is not a supported runtime switch.** The pinned source labels it “Headless backend for tests,” notes missing dmabuf support, and can add deterministic `headless-N` outputs. But the pinned CLI has no `--headless` option, and normal `main.rs` calls `State::new(..., false, ...)`; the backend is used by Niri's Rust tests, not by the packaged compositor session. Exposing it would require an upstream/code patch and still would not validate DRM, greetd, or logind. [Pinned `headless.rs`](https://github.com/YaLTeR/niri/blob/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6/src/backend/headless.rs) [Pinned `cli.rs`](https://github.com/YaLTeR/niri/blob/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6/src/cli.rs) [Pinned `main.rs`](https://github.com/YaLTeR/niri/blob/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6/src/main.rs)

6. **Nested compositor is a useful secondary test, not session replacement.** Start an outer compositor with a headless/software backend, set `WAYLAND_DISPLAY`, and run plain `niri` so it chooses winit. This gives a deterministic nested output and can test Wayland clients/layout/IPC using llvmpipe. It intentionally bypasses Niri's TTY/DRM/libinput/logind path; running `niri-session` defeats nesting because session mode removes inherited display variables. Niri upstream calls nested mode its main development path, but also documents working hardware acceleration as required for normal standalone packaging. [Developing Niri](https://github.com/YaLTeR/niri/wiki/Developing-niri) [Packaging Niri](https://niri-wm.github.io/niri/Packaging-niri.html) [Pinned backend selection](https://github.com/YaLTeR/niri/blob/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6/src/niri.rs)

### Recommended repository direction

- Keep QEMU for all three authoritative host smokes and specifically for Sonic login/session/graphics.
- Add explicit `virtio-gpu-pci` to Sonic's VM-only override; retain guest Mesa and verify renderer/output information in the test log.
- Strengthen Sonic with `niri msg --json outputs`, a current-mode assertion, a trivial Wayland client, and `machine.screenshot(...)` after login.
- If runtime is the problem, add a **separate** container check family containing only descriptors declared container-safe. Do not infer safety from phase. Add descriptor metadata such as `backends = [ "qemu" "nspawn" ]`.
- Exclude graphical login/Niri/DMS rendering, kernel journal, and kernel-module checks from nspawn. Keep PipeWire/portal container assertions explicitly labeled “control-plane only.”
- Treat k3s and hardening-heavy services as opt-in container experiments with documented overrides, not automatic migrations.

## Sources

- Kept: [Pinned nixpkgs test manual](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/doc/manual/development/writing-nixos-tests.section.md) — authoritative support and trade-offs at the repository lock.
- Kept: [Pinned nixpkgs QEMU module](https://github.com/NixOS/nixpkgs/blob/9f78f44a87948854445dae0b6bf82b2e87e4efb5/nixos/modules/virtualisation/qemu-vm.nix) — authoritative meaning of `graphics` and QEMU options.
- Kept: [Pinned Niri source](https://github.com/YaLTeR/niri/tree/feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6) — locked backend/CLI behavior.
- Kept: [systemd manuals](https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html) — container, PAM, logind, session, and seat contracts.
- Kept: [Linux VKMS documentation](https://docs.kernel.org/gpu/vkms.html) — purpose and kernel nature of VKMS.
- Kept: [QEMU virtio-gpu documentation](https://www.qemu.org/docs/master/system/devices/virtio/virtio-gpu.html) — 2D software and accelerated backend requirements.
- Kept: repository aspect and host files linked above — direct evidence for current probes.
- Dropped: blogs, forums, third-party container recipes, and benchmark summaries — non-primary or unnecessary.
- Dropped: old Niri/QEMU failure reports as conclusions — useful leads, but current locked source and official device documentation are stronger evidence.

## Gaps

- A proof run confirmed that pinned Niri rejects llvmpipe on 2D virtio-gpu by design. A narrow VM-only patch allowing the single software renderer produced a real output and passed the Niri IPC assertion. VirGL and Rutabaga both failed before guest boot because the sandbox lacks a usable accelerated host graphics backend.
- The current builder lacks `auto-allocate-uids` and the `uid-range` system feature required by nixpkgs nspawn tests. Container checks cannot be enabled in the default flake check until the builder contract changes. The precise nspawn compatibility of k3s and hardening-heavy units would still need proof tests.
- Niri's headless backend could evolve or become CLI-exposed after the locked revision; this note describes `feb3e43f1475e0865bb89cbd1e898b34d1d2ccf6`.
