# Plannotator/OMP decision

## Decision

Use the official Pi extension in OMP, not the OpenCode plugin:

```bash
omp plugin install @plannotator/pi-extension@0.27.3
```

`@plannotator/opencode` is an OpenCode-plugin protocol and host integration; it
cannot run in Pi/OMP. The supported integration is the Pi extension, whose
upstream package is version `0.27.3` ([package manifest](https://github.com/backnotprop/plannotator/blob/main/apps/pi-extension/package.json)).
The official setup and command surface are documented in the [Pi integration
guide](https://docs.plannotator.ai/open-source/agents/pi) and its
[upstream README](https://github.com/backnotprop/plannotator/blob/main/apps/pi-extension/README.md).

The live OMP installation was checked with `omp plugin list` and
`omp plugin doctor`: the extension is installed and healthy. OMP remains
selected on Sonic. OpenCode is removed from both Sonic and Palantir host
selections until OpenCode 2.0 is stable; the existing
`modules/aspects/cli/opencode/default.nix` remains dormant for that future
cutover. Do not reuse the OpenCode plugin or add it back to either host.

## Supported use

- `/plannotator-review` opens the detected VCS review. In this repository, use `/plannotator-review --git` when Call flow is required; the currently selected native jj mode reports `vcs-unsupported`.
- `/plannotator-annotate path/to/spec.md` annotates a document.
- `/plannotator-last` annotates the latest agent message.
- `/plannotator-plan-mode` enters Plannotator plan mode.
- Pass `--git` to `/plannotator-review` to force Git. The extension's review
  behavior and provider flags are specified in the [Pi README](https://github.com/backnotprop/plannotator/blob/main/apps/pi-extension/README.md#code-review).

## Call flow and VCS boundaries

Call flow is mutable Plannotator UI state, not Nix-owned configuration. The
review UI writes `~/.plannotator/config.json`; keep its `callFlow` flag enabled
there. The UI also owns the managed runtime under
`~/.plannotator/vendor/call-flow`, currently CallDiff `0.4.1`. Do not create a
Nix-managed config file or vendor CallDiff. Plannotator's implementation pins
CallDiff and requires Node >=22 ([call-flow source](https://github.com/backnotprop/plannotator/blob/main/packages/shared/call-flow.ts);
[configuration docs](https://docs.plannotator.ai/open-source/reference/configuration)).

Native jj call flow is supported only by snapshot-capable modes such as
`jj-current` and `jj-line`; it is not supported by `jj-all` or a multi-repository
workspace. If the selected jj mode reports unsupported call flow, rerun
`/plannotator-review --git` to use the colocated Git provider. These boundaries
follow Plannotator's [local-change provider documentation](https://docs.plannotator.ai/open-source/workflows/local-changes).

## Sources and non-goals

The [official Pi integration guide](https://docs.plannotator.ai/open-source/agents/pi)
is authoritative for installation and commands. This note intentionally does
not recommend `@plannotator/opencode`, the standalone Plannotator installer,
`sem`, or any Nix-owned `~/.plannotator/config.json`.
