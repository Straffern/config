# HermesPilot iOS → Palantir Hermes Agent

## Result

HermesPilot is **not** a native Hermes API/WebSocket client that can be pointed at
`http://palantir:8642`. The supported connection path is **Hermes Link**:
install `@hermespilot/link` on the machine running Hermes, pair it with the
HermesPilot app, and let Link bridge the app to Hermes. Pairing requires the
HermesPilot Server and Relay; the Link CLI prints a QR code or a ten-minute
manual pairing code. The published Link package explicitly says that Relay and
Server are disabled until pairing and that a relay-only environment uses Relay.

Sources (official/published primary sources):

- [HermesPilot App Store listing](https://apps.apple.com/us/app/hermespilot-for-hermes-users/id6765671330)
- [Hermes Link README, v1.0.1](https://cdn.jsdelivr.net/npm/@hermespilot/link@1.0.1/README.md)
- [Hermes Link published source bundle, v1.0.1](https://cdn.jsdelivr.net/npm/@hermespilot/link@1.0.1/dist/chunk-HAK5ZDUJ.js)
- [Pinned Hermes source in this checkout (rev `2d9fd870b6d105e3b367aaa97477931b6671192e`)](https://github.com/NousResearch/hermes-agent/tree/2d9fd870b6d105e3b367aaa97477931b6671192e)

## Protocol, ports, and paths

There are three distinct local/network surfaces:

1. **Hermes Agent API Server:** HTTP, OpenAI-compatible, default
   `127.0.0.1:8642`. The base URL is `http://127.0.0.1:8642/v1`; useful
   paths include `POST /v1/responses`, `POST /v1/chat/completions`, and
   `GET /health`. This is the backend Link drives, not the URL to enter in
   HermesPilot. Hermes documents bearer authentication and the
   `API_SERVER_ENABLED=true` / `API_SERVER_KEY=...` settings.
2. **Hermes Link local API:** HTTP on port `52379` by default (the published
   source constant is `LINK_DEFAULT_PORT = 52379`). Link's Node server calls
   `listen(port)` without a host, so this is a wildcard bind, **not**
   `127.0.0.1`; keep the firewall closed and verify the actual socket. Link's
   local API routes include `/api/v1/...`; requests require
   `Authorization: Bearer <device-access-token>` or a valid HermesPilot
   app-connect JWT. Link's source also accepts the
   `X-HermesPilot-App-Connect-Token` ownership header.
3. **Relay control channel:** Link makes outbound HTTPS/WSS connections to
   `hermes-server.clawpilot.me` and `hermes-relay.clawpilot.me`; its Relay
   WebSocket path is
   `wss://<relay>/api/v1/relay/link/connect?link_id=<id>` (the published source
   constructs this from the Relay base URL and changes `https` to `wss`). The
   app normally reaches Link through Relay, not by reaching Palantir's local
   port directly.

Primary protocol references:

- [Hermes Agent programmatic integration](https://hermes-agent.nousresearch.com/docs/developer-guide/programmatic-integration)
  defines API Server as HTTP + SSE and TUI Gateway as JSON-RPC over stdio or
  WebSocket; it does not define an iOS-specific gateway endpoint.
- [Hermes Agent API Server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
  documents `/v1/responses`, `/v1/chat/completions`, `/v1/runs`, SSE events,
  `/v1/models`, `/v1/capabilities`, and `/health`.
- [Hermes Link README](https://cdn.jsdelivr.net/npm/@hermespilot/link@1.0.1/README.md)
  says Link calls the local Hermes API and can start `hermes gateway run
  --replace` when the API is unavailable.
- [Hermes Link source: defaults and auth](https://cdn.jsdelivr.net/npm/@hermespilot/link@1.0.1/dist/chunk-HAK5ZDUJ.js)
  contains `DEFAULT_HERMES_API_SERVER_PORT = 8642`, `LINK_DEFAULT_PORT = 52379`,
  the Relay WebSocket path, and bearer/JWT validation.

## Authentication and TLS

- Hermes API Server requires a bearer key when enabled. Do not reuse the
  model-provider key; create a separate random `API_SERVER_KEY` and keep it in
  SOPS. Hermes' documented curl example uses
  `Authorization: Bearer <API_SERVER_KEY>`.
- Hermes Link pairing creates device/app credentials. Do not paste a Hermes
  provider key, SOPS value, or the API server key into the app.
- The Relay path is TLS (`wss://`). For direct LAN access, use HTTPS/WSS with
  a certificate trusted by iOS. Plain `http://` may work only for a deliberately
  local/LAN deployment and is not the safe default; iOS App Transport Security
  and certificate trust make an IP address with a self-signed certificate a
  poor design.
- A Tailscale IP (`100.x.y.z`) is reachable from iOS only while the Tailscale
  app is connected and ACLs permit it. A MagicDNS hostname is generally usable
  for routing, but HTTPS still requires a certificate whose name iOS trusts.
  Prefer Relay, or terminate HTTPS with a publicly/ACME-trusted name. Tailscale's
  own guidance recommends HTTPS for tailnet services: [Secure the network](https://tailscale.com/kb/1429/secure).

**Important:** HermesPilot's supported pairing flow is Relay-based. Link makes
an outbound WSS connection, so Tailscale is **not required** for the supported
Relay flow. The app should not be configured with Palantir's Tailscale
hostname. Tailscale is relevant only if a future HermesPilot UI and Link
direct/LAN mode are deliberately used (`hermeslink config set lan-host ...`).

## Current `~/.dotfiles` findings

- Palantir enables the native `services.hermes` and Hindsight options, plus
  the repository Tailscale service. A live audit found `tailscaled` logged out
  (`NeedsLogin`) with no tailnet IP, so direct Tailscale access is not currently
  available.
- The Hermes module now enables the API server and declarative Hermes Link;
  before this change, the live Hermes 0.18.2 gateway had no HTTP listener
  because API server was disabled.
- The module's Hindsight URL is local (`http://127.0.0.1:8888`).
- Live SSH inspection confirmed Hermes `0.18.2` is running. No secrets were
  read.
- The flake pins NousResearch/hermes-agent at
  `2d9fd870b6d105e3b367aaa97477931b6671192e` (see
  [`flake.lock`](../flake.lock)). The upstream module exposes
  `services.hermes-agent.settings`, `environment`, and `environmentFiles`; its
  source is [nix/nixosModules.nix at the pinned revision](https://raw.githubusercontent.com/NousResearch/hermes-agent/2d9fd870b6d105e3b367aaa97477931b6671192e/nix/nixosModules.nix).

## Applied declarative Nix configuration

The repository now provides the public `hermes-link` package from the pinned
`@hermespilot/link@1.0.1` npm package under the owning service aspect, with a
pinned `npmDepsHash` and no runtime `npx`/network fetch. The Hermes service
aspect enables Link by default, declares the expected SOPS key
`hermes_api_server_key` from the host SOPS file, and adds these placeholders to
the existing `hermes-env` template:

```text
API_SERVER_ENABLED=true
API_SERVER_HOST=127.0.0.1
API_SERVER_PORT=8642
API_SERVER_KEY=<SOPS placeholder>
```

It adds a systemd `hermes-link.service` running as the
`services.hermes-agent` user/group with `HOME`, `HERMES_HOME`, and
`HERMESLINK_HOME` under the Hermes state directory. The unit consumes the same
`hermes-env` file, sets `HERMESLINK_GATEWAY_AUTOSTART=false`, runs the absolute
store binary with `hermeslink daemon`, uses `Restart=always`/`RestartSec=5s`,
`UMask=0077`, and starts after `network-online.target` and
`hermes-agent.service`. Port 8642 remains loopback-only; Link's wildcard
52379 listener remains firewall-closed. No Tailscale dependency was added.

The remaining user steps are: add the `hermes_api_server_key` value to the
existing Palantir SOPS file, deploy, then perform the one-time safe pairing
sequence below. Do not read or print the secret.

## Manual rollout and iOS steps

1. Add the `hermes_api_server_key` value to the existing Palantir SOPS file,
   then deploy the configuration. Never print or validate the secret value.
2. Confirm the managed `hermes-agent.service` is active with
   `API_SERVER_ENABLED=true`; check `curl -fsS http://127.0.0.1:8642/health`
   and an authenticated `GET /v1/capabilities` without echoing the key.
3. For the first pairing, stop the enabled unit before invoking Link so
   `Restart=always` cannot race a detached supervisor:
   `sudo systemctl stop hermes-link.service`. Then run
   `sudo -u hermes env HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes/.hermes /run/current-system/sw/bin/hermeslink pair`.
   Pairing needs outbound HTTPS/WSS access to `hermes-server.clawpilot.me`
   and `hermes-relay.clawpilot.me`. Log in to HermesPilot on iOS, scan the QR
   code (or enter the short-lived manual code), and wait for the claim.
4. The first successful `hermeslink pair` starts a background Link and enables
   boot autostart. Disable that duplicate lifecycle and stop it:
   `sudo -u hermes env HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes/.hermes /run/current-system/sw/bin/hermeslink autostart off`
   followed by
   `sudo -u hermes env HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes/.hermes /run/current-system/sw/bin/hermeslink stop`.
   Then start the Nix-managed unit with
   `sudo systemctl start hermes-link.service`; `wantedBy` handles enablement.
   Do not leave both the CLI background daemon and systemd unit running.
5. Run the same hermes-scoped `hermeslink status` and `doctor` commands, plus
   its logs. Confirm Link is listening on port `52379`; because the Node
   server binds wildcard, do not assume loopback and do not publish the port.
   Keep the firewall closed.
6. Send a harmless test prompt from the app, then check the Hermes and Link
   service logs for one completed request. Use the app's reconnect path after
   restarting Link.

Do not run `hermes gateway enroll`; that is an unrelated relay flow, not part
of HermesPilot Link pairing.

## Verification commands (safe forms)

```sh
# no secrets printed
systemctl is-active hermes-agent.service
ss -ltn '( sport = :8642 or sport = :52379 )'
sudo -u hermes env HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes/.hermes \
  /run/current-system/sw/bin/hermeslink status
sudo -u hermes env HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes/.hermes \
  /run/current-system/sw/bin/hermeslink doctor
```

Use a shell variable populated by a protected mechanism for real authenticated
checks; never place the value in shell history or documentation.

## Risks and non-goals

- Exposing Hermes API or Link directly grants agent/tool access, not merely
  chat access. A leaked key or pairing token can enable file, terminal, memory,
  and messaging operations. Keep Hermes API loopback-only; Link binds wildcard,
  so rely on the closed firewall and Relay rather than assuming loopback.
- Do not forward 8642/52379 through a public reverse proxy without HTTPS,
  authentication, rate limiting, and an explicit threat model.
- This note applies declarative Nix Link configuration but does not modify
  SOPS values, live Palantir state, or Tailscale policy.
