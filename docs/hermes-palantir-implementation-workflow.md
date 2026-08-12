# Palantir Hermes and Hindsight workflow

## Scope

Hermes is owned by the Den service aspect under
`modules/aspects/services/hermes/`. Palantir selects that aspect through its
host entity. Hindsight remains a local service capability. Alex's Home Manager
configuration is integrated through the Palantir entity; this workflow does not
create a separate user output.

The live contract is native NixOS options, lexical package values, encrypted
SOPS references, and explicit host membership. The generated root `flake.nix`
is written by flake-file and is never hand-edited.

## Security gates

- Never read, decrypt, print, grep, validate, or re-encrypt SOPS data here.
- Secret names may be documented; secret values must never appear in notes,
  shell history, logs, or generated options.
- Do not deploy or activate a host as part of documentation or source review.
- Keep Hermes API and Hindsight loopback-only unless a separately reviewed
  network policy explicitly changes that boundary.

## Current Palantir behavior

The service uses the pinned `hermes-agent` input and native
`services.hermes-agent` options. The environment template references the
existing AI and Telegram credentials and limits Telegram access to the approved
user identifier. Hindsight binds locally on ports `8888` and `9999`; Hermes'
`memory.memory_enabled` flag alone does not select Hindsight.

Hermes Link is a lexical package value owned by the service aspect. It is built
from the pinned `@hermespilot/link` source with no runtime network fetch. Keep
its wildcard listener firewall-closed and use the Relay pairing flow described
in `hermespilot-palantir.md`.

## Planned options

Use native options directly; the illustrative values below contain no secret
material:

```nix
services.hermes = {
  enable = true;
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
  web.backend = "exa";
  xSearch.enable = false;
};
```

Optional dependency groups must be explicit in the service package override
when upstream requires them (`messaging`, `hindsight`, and `exa`). Do not use a
catch-all dependency group without evidence that it is required. Do not add
Firecrawl or voice support without a separate decision.

## Implementation sequence

1. Verify upstream Hermes option names at the pinned revision.
2. Update the Hermes service aspect and its lexical package value.
3. Select Hermes and Hindsight from the Palantir host entity.
4. Add only secret references; the user owns SOPS edits and deployment.
5. Regenerate the root flake after declaration changes:

   ```bash
   nix run .#write-flake
   ```

6. Confirm the generated root is byte-identical on a second writer run and run
   the exported staleness check. Review generated input/follow changes before
   updating `flake.lock`.

If the generated root is missing or cannot evaluate, restore the last committed
root or bootstrap the pinned writer, then regenerate:

```bash
nix-shell https://github.com/denful/flake-file/archive/v0.6.0.tar.gz -A flake-file.sh --run bootstrap
nix run .#write-flake
```

## Local verification

Safe checks may inspect service status, loopback listeners, and derivation
metadata without exposing credentials:

```bash
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.enable
nix eval .#nixosConfigurations.palantir.config.services.hermes-agent.settings.model.default
systemctl is-active hermes-agent.service
ss -ltn '( sport = :8642 or sport = :8888 or sport = :9999 )'
```

Deployment and activation remain user-owned. Use `jj` for repository history.
