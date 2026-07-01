# Palantir Hermes + Hindsight Revamp Plan

## Scope

Target host: `palantir` in `~/.dotfiles`.

Deliverables for implementation phase:

- update/pin Hermes input intentionally
- factor palantir Hermes config into reusable NixOS module
- keep existing Telegram bot value, but rename the SOPS key/reference to `hermes_telegram_bot_token` during implementation
- wire local Hindsight on palantir
- configure Exa web search/extract first
- add X/xAI search support without touching SOPS contents
- choose model routing deliberately, with DeepSeek V4 Flash as cost-first candidate
- verify locally only
- leave deploy-rs execution to user
- commit each behavior atomically with `jj`

## Hard constraints

- Do not read, decrypt, edit, re-encrypt, grep, or validate SOPS files.
- Do not deploy.
- Do not run `nh os switch`, `nixos-rebuild switch`, `deploy`, or `deploy-rs` activation.
- Telegram: preserve the existing bot token value, but plan to rename the key/reference from `openclaw_telegram_bot_alex` to `hermes_telegram_bot_token`. The agent must not perform the SOPS edit; user does it before deploy.
- Use `jj`, never `git`.
- Each commit must compile/evaluate before committing.
- Prefer Exa first because user already has Exa. Add Firecrawl only behind a later decision gate.

## Current repo facts to preserve

- palantir Hermes config is currently inline in `systems/x86_64-linux/palantir/default.nix`.
- `flake.nix` already has `hermes-agent` input and imports `hermes-agent.nixosModules.default`.
- Existing palantir Hermes env template uses:
  - `openclaw_ai_api_key` for `OPENAI_API_KEY`
  - `openclaw_telegram_bot_alex` for `TELEGRAM_BOT_TOKEN` today; target key name is `hermes_telegram_bot_token` after user renames/adds it in SOPS
  - `TELEGRAM_ALLOWED_USERS=6045704025`
- Existing Hindsight module lives at `modules/nixos/services/hindsight/default.nix`.
- Hindsight service binds local ports `127.0.0.1:8888` and `127.0.0.1:9999`.
- Hermes built-in `memory.memory_enabled = true` is not the same as the Hindsight plugin.

## Source-verify before implementation

Before editing Nix behavior, inspect the pinned/upstream Hermes source for exact option names:

- `nix/nixosModules.nix`
- `nix/packages.nix`
- `plugins/memory/hindsight`
- web/search provider config defaults
- model/provider config docs or defaults

Questions to answer from source, not guess:

- exact package override interface for optional dependency groups
- exact Hindsight memory provider config key
- exact Hindsight env var names; expected at least `HINDSIGHT_API_URL`
- exact Exa web config key; expected env `EXA_API_KEY`
- exact `x_search` config key; expected env `XAI_API_KEY`
- whether `services.hermes-agent.extraDependencyGroups` exists directly or package override is required
- whether `services.hermes-agent.mcpServers` exists and should be avoided/used

## Model research summary

### Candidates

| Model | Role | Why | Risk |
| --- | --- | --- | --- |
| `deepseek/deepseek-v4-flash` | cost-first main model | Very low OpenRouter price, 1M context, positioned for fast/high-throughput agent workflows | lower max output than premium models; quality/tool reliability must be smoke-tested |
| `~anthropic/claude-sonnet-latest` or explicit Sonnet 4.x | reliability-first main/fallback | strongest real-world agent/coding/browser reliability signal | much higher cost |
| `~google/gemini-flash-latest` / Gemini Flash | auxiliary/compression/multimodal | good price/capability, strong long-context/multimodal fit | not as cheap as DeepSeek; provider quirks possible |
| `minimax/minimax-m2` | coding/agent value fallback | agentic/coding positioning, long outputs | less obviously best for browser/research vs Claude/Gemini/DeepSeek |
| OpenAI GPT-5.1 / GPT-4.1 | premium fallback | strong general tool-use; GPT-4.1 large context | not cost leader |

### Recommendation

Use OpenRouter as Hermes provider.

Default plan, cost-first:

```nix
model = {
  base_url = "https://openrouter.ai/api/v1";
  default = "deepseek/deepseek-v4-flash";
};
```

Rationale:

- user is already considering DeepSeek V4 Flash for affordability
- good first bang-for-buck default
- use smoke tests to decide whether quality is enough
- keep Claude Sonnet as documented fallback/manual escalation, not default cost sink

Reliability-first alternative:

```nix
model.default = "~anthropic/claude-sonnet-latest";
```

Auxiliary/compression if Hermes supports separate setting:

```nix
compression = {
  enabled = true;
  threshold = 0.85;
  summary_model = "~google/gemini-flash-latest";
};
```

Important: current palantir `base_url = "https://opencode.ai/zen/go/v1"` may not accept OpenRouter model names. Switching to DeepSeek V4 Flash means switching base URL and env/key semantics too. Do not point OpenRouter model IDs at OpenCode proxy unless source/docs prove compatibility.

## Web backend decision

Use Exa first.

Reasons:

- user already has Exa
- one provider is simpler than two
- Exa is enough for search/research and many extraction tasks
- Firecrawl can be added later if Exa is weak on page crawling/JS-heavy extraction

Do not add Firecrawl in first implementation unless source proves Exa unsupported by current Hermes package/config.

Expected env:

```env
EXA_API_KEY=<user adds through SOPS later>
```

Expected config shape must be source-verified before implementation.

## X Search decision

Add module support for X Search, but enable on palantir only if a non-SOPS-inspected secret name is provided by config.

Expected env:

```env
XAI_API_KEY=<user adds through SOPS later>
```

Expected Hermes config:

```nix
x_search = {
  model = "grok-4.20-reasoning";
  timeout_seconds = 180;
  retries = 2;
};
```

X Search is for X-native claims/discourse with citations. It is not a general X account automation API.

## Hindsight decision

Use existing local Hindsight module on palantir.

Target Hermes env:

```env
HINDSIGHT_API_URL=http://127.0.0.1:8888
```

Implementation must source-verify exact Hermes memory provider settings before wiring. Do not assume this is enough:

```nix
memory.memory_enabled = true;
```

That flag alone enables Hermes memory, not necessarily the Hindsight backend.

## Proposed reusable module

Create:

```text
modules/nixos/services/hermes/default.nix
```

Minimal option surface:

```nix
${namespace}.services.hermes = {
  enable = true;

  # preserve existing credentials by default
  aiApiKeySecret = "openclaw_ai_api_key";
  telegramBotTokenSecret = "hermes_telegram_bot_token";
  telegramAllowedUsers = [ "6045704025" ];

  model = {
    default = "deepseek/deepseek-v4-flash";
    baseUrl = "https://openrouter.ai/api/v1";
  };

  hindsight = {
    enable = true;
    apiUrl = "http://127.0.0.1:8888";
  };

  web = {
    enable = true;
    backend = "exa";
    exaApiKeySecret = null; # user supplies name after SOPS edit outside agent
  };

  xSearch = {
    enable = false;
    xaiApiKeySecret = null; # user supplies name after SOPS edit outside agent
  };

  settings = { };
};
```

Notes:

- `aiApiKeySecret` default preserves current behavior for pure extraction commit.
- `telegramBotTokenSecret` target default is `hermes_telegram_bot_token`; pure extraction may temporarily keep `openclaw_telegram_bot_alex` until user completes SOPS rename.
- Later model switch should prefer an OpenRouter key secret name, but this agent must not inspect SOPS. If no existing non-secret declaration names an OpenRouter key for palantir, leave option documented for user to fill.
- Optional secrets are `null` until user adds SOPS entries and tells us names.
- Module can emit env vars conditionally only when secret option is non-null.

## Package extras plan

Hermes optional dependencies must be explicit under Nix. `toolsets = [ "all" ]` does not guarantee runtime imports for optional providers.

Initial extras:

```nix
extraDependencyGroups = [
  "messaging"
  "hindsight"
  "exa"
];
```

If upstream uses package override:

```nix
services.hermes-agent.package = pkgs.hermes-agent.override {
  extraDependencyGroups = [
    "messaging"
    "hindsight"
    "exa"
  ];
};
```

If upstream NixOS module has direct option:

```nix
services.hermes-agent.extraDependencyGroups = [
  "messaging"
  "hindsight"
  "exa"
];
```

Do not use `full` unless override path is broken. `full` is bigger blast radius.

Do not add `firecrawl` initially.

Do not add `voice` initially.

## Atomic `jj` workflow

### Commit 1 — docs only

Files:

- `docs/hermes-palantir-implementation-workflow.md`

Changes:

- Add this plan.
- No Nix behavior changes.

Verify:

```sh
jj diff --stat
```

Commit:

```sh
jj commit -m "docs: plan palantir hermes revamp"
```

### Commit 2 — update Hermes input only

Files:

- `flake.lock`

Changes:

- Update only `hermes-agent` input.
- Do not update unrelated inputs.

Command:

```sh
nix flake lock --update-input hermes-agent
```

Verify:

```sh
jj diff --stat
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.enable
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "flake: update hermes agent"
```

### Commit 3 — pure module extraction

Files:

- `modules/nixos/services/hermes/default.nix`
- `systems/x86_64-linux/palantir/default.nix`

Changes:

- Move existing palantir Hermes config into reusable module.
- Preserve exact current behavior:
  - existing token secret names for pure extraction; later commit switches Telegram reference to `hermes_telegram_bot_token` after user SOPS rename
  - current model/base URL
  - current `toolsets`
  - current memory flags
  - current systemd SOPS dependency/restart trigger
- In palantir, replace inline Hermes block with module enable call.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix systems/x86_64-linux/palantir/default.nix
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.enable
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.model.default
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.model.base_url
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "nixos: extract palantir hermes module"
```

### Commit 4 — Hermes optional dependency groups

Files:

- `modules/nixos/services/hermes/default.nix`

Changes:

- Add package/extras wiring.
- Include only:
  - `messaging`
  - `hindsight`
  - `exa`
- Keep package override configurable.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.package.name
nix build .#nixosConfigurations.palantir.config.services.hermes-agent.package --dry-run
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "nixos: include hermes optional extras"
```

### Commit 5 — OpenRouter model routing

Files:

- `modules/nixos/services/hermes/default.nix`
- `systems/x86_64-linux/palantir/default.nix` only if host-specific override needed

Changes:

- Add module options for provider key secret, model, base URL.
- Set target model to `deepseek/deepseek-v4-flash` if an OpenRouter key secret name is provided by config.
- Keep existing OpenClaw/OpenCode config as fallback if no OpenRouter secret name is available without reading SOPS.
- Source verification found upstream `services.hermes-agent.extraDependencyGroups` exists directly; prefer it over manual package override.
- Do not inspect SOPS to discover key names.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix systems/x86_64-linux/palantir/default.nix
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.model.default
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.model.base_url
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "nixos: configure hermes model routing"
```

### Commit 6 — local Hindsight wiring

Files:

- `systems/x86_64-linux/palantir/default.nix`
- `modules/nixos/services/hermes/default.nix`

Changes:

- Enable existing `asgaard.services.hindsight` on palantir.
- Enable Podman if needed by existing Hindsight module.
- Add `HINDSIGHT_API_URL=http://127.0.0.1:8888` to Hermes env when Hindsight is enabled.
- Add Hermes systemd dependency on Hindsight service.
- Add exact Hermes memory-provider config only if source verified.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix systems/x86_64-linux/palantir/default.nix
nix eval .#nixosConfigurations.palantir.config.virtualisation.oci-containers.containers.hindsight.image
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.memory.memory_enabled
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "nixos: connect palantir hermes to hindsight"
```

### Commit 7 — Exa web backend support

Files:

- `modules/nixos/services/hermes/default.nix`
- `systems/x86_64-linux/palantir/default.nix` only if host-specific secret name configured

Changes:

- Add Exa module options.
- Add `EXA_API_KEY` to env only when `web.exaApiKeySecret != null`.
- Configure Hermes web backend to Exa using source-verified config keys.
- Do not add Firecrawl.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix systems/x86_64-linux/palantir/default.nix
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.web
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "nixos: configure hermes exa web backend"
```

### Commit 8 — X Search support

Files:

- `modules/nixos/services/hermes/default.nix`
- `systems/x86_64-linux/palantir/default.nix` only if host-specific secret name configured

Changes:

- Add xAI/X Search module options.
- Add `XAI_API_KEY` to env only when `xSearch.xaiApiKeySecret != null`.
- Configure `x_search` settings.
- Keep disabled until user supplies secret name.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix systems/x86_64-linux/palantir/default.nix
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.x_search
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
```

Commit:

```sh
jj commit -m "nixos: add hermes x search support"
```

### Commit 9 — final cleanup/evaluation

Files:

- touched Nix files only

Changes:

- Remove stale inline comments made obsolete by module extraction.
- Keep palantir host file host-specific.
- No deploy.

Verify:

```sh
nixfmt-rfc-style modules/nixos/services/hermes/default.nix systems/x86_64-linux/palantir/default.nix
nix flake check --no-build
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
jj diff --stat
```

Commit:

```sh
jj commit -m "nixos: tidy palantir hermes wiring"
```

## Workflowz implementation graph

Use this as deterministic subagent workflow when implementing.

### Wave 1 — read-only source verification

Run in parallel:

1. **Hermes Nix option verifier**
   - read upstream `nix/nixosModules.nix` and `nix/packages.nix`
   - return exact package/extras option syntax
   - return whether direct `extraDependencyGroups` option exists

2. **Hermes Hindsight verifier**
   - read `plugins/memory/hindsight`
   - return exact config keys/env vars
   - confirm local URL should be `http://127.0.0.1:8888`

3. **Hermes web/X verifier**
   - read web provider and x_search docs/source
   - return exact Exa config keys and optional dependency group name
   - return exact xAI env/config keys

4. **Model verifier**
   - verify current OpenRouter model IDs and price/capability notes
   - compare DeepSeek V4 Flash vs Gemini Flash vs Claude Sonnet vs MiniMax M2
   - recommend default + fallback with exact slugs

Barrier: synthesize exact config contract. No edits until all return.

### Wave 2 — docs + pure extraction

Run one editor agent for pure module extraction only after docs commit exists:

- add `modules/nixos/services/hermes/default.nix`
- move current inline Hermes behavior unchanged
- update palantir call site
- no package/model/Hindsight/web changes yet

Orchestrator verifies eval/build, then commits.

### Wave 3 — independent feature edits

After extraction commit, split feature edits if file conflicts manageable; otherwise serialize because same module file is shared.

Preferred order to keep diffs atomic:

1. package extras
2. model routing options
3. Hindsight wiring
4. Exa backend
5. X Search support

Each feature agent receives:

- exact source-verified config keys from Wave 1
- explicit file targets
- no SOPS read/edit rule
- no deploy rule
- no formatter/test rule; orchestrator runs verification

### Wave 4 — adversarial review

Run parallel reviewers:

1. **SOPS/token reviewer**
   - refute any SOPS file access
   - confirm existing Telegram token preserved

2. **Nix eval reviewer**
   - inspect final Nix config for wrong option names
   - check package extras shape

3. **Runtime wiring reviewer**
   - check Hindsight URL/ports/service dependencies
   - check web/X env gating

4. **Model/cost reviewer**
   - confirm model choices match plan
   - ensure DeepSeek default is deliberate and fallback documented

Only fix confirmed findings.

### Wave 5 — final verification and commits

For each atomic change:

```sh
nixfmt-rfc-style <changed nix files>
nix eval <targeted attrs>
nix build .#nixosConfigurations.palantir.config.system.build.toplevel --dry-run
jj diff --stat
jj commit -m "<focused message>"
```

No deployment.

## User SOPS instructions for later

User must add/edit SOPS entries manually. Suggested names:

```yaml
hermes_openrouter_api_key: <OpenRouter key>
hermes_exa_api_key: <Exa key>
hermes_xai_api_key: <xAI key, optional>
hermes_telegram_bot_token: <same token value currently stored under openclaw_telegram_bot_alex>
```

Telegram rename instruction:

- copy/rename existing `openclaw_telegram_bot_alex` value to `hermes_telegram_bot_token` in SOPS
- keep bot token value unchanged
- after deploy succeeds, remove old `openclaw_telegram_bot_alex` only if no other service references it

After user adds secrets, configure module options with those secret names, for example:

```nix
${namespace}.services.hermes = {
  aiApiKeySecret = "hermes_openrouter_api_key";
  telegramBotTokenSecret = "hermes_telegram_bot_token";
  web.exaApiKeySecret = "hermes_exa_api_key";
  xSearch = {
    enable = true;
    xaiApiKeySecret = "hermes_xai_api_key";
  };
};
```

## User deployment handoff

Deployment is user-owned. After all implementation commits are green, user deploys with deploy-rs.

Expected command shape, to be confirmed from flake deploy output:

```sh
deploy .#palantir
```

or:

```sh
nix run github:serokell/deploy-rs -- .#palantir
```

Post-deploy checks for user:

```sh
systemctl status hermes-agent --no-pager
journalctl -u hermes-agent -b --no-pager -n 200
systemctl status podman-hindsight --no-pager
journalctl -u podman-hindsight -b --no-pager -n 200
curl -sS http://127.0.0.1:8888/health
```

## Firecrawl decision gate

Add Firecrawl later only if Exa fails on concrete tasks:

- JS-heavy page extraction poor
- crawl depth needed
- browser-like extraction needed
- Hermes source strongly prefers Firecrawl for intended browser backend

Then add, manually through SOPS:

```yaml
hermes_firecrawl_api_key: <Firecrawl key>
```

And add dependency group/config:

```nix
extraDependencyGroups = [
  "messaging"
  "hindsight"
  "exa"
  "firecrawl"
];
```

## Open questions

- Exact OpenRouter secret name user will add: `hermes_openrouter_api_key` ok?
- Exact Exa secret name user will add: `hermes_exa_api_key` ok?
- Telegram key rename target `hermes_telegram_bot_token` ok?
- Enable X Search in first implementation, or only module support until key exists?
