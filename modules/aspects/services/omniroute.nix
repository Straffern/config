{den, ...}: let
  port = 20128;
  image = "docker.io/cheaperinference/omniroute:latest";
  # Restarting the service upgrades OmniRoute.
  pull = "newer";
  dataDir = "/var/lib/omniroute";
  # Capability token for the Codex app-server WebSocket, shared by both containers.
  codexTokenDir = "/var/lib/omniroute-codex";
  codexAppServer = "ws://127.0.0.1:1456";
  # The image runs as `node`.
  uid = "1000";

  # The only providers whose models reach /v1/models, by OmniRoute provider id.
  providers = [
    "claude" # Claude Code subscription
    "anthropic"
    # ChatGPT plan: OpenAI's Sign in with ChatGPT plan usage for self-hosted apps, and the official
    # `codex app-server` holding its own login. The `codex` provider replays the CLI's token instead.
    "chatgpt"
    "codex-app-server"
    "openai"
    "gemini"
    "xai"
    "opencode-go"
    "opencode-zen"
  ];

  # Keyless providers are advertised without a connection, and their image and video models are
  # outside the allowlist's reach, so they are refused outright. A release that adds one shows up
  # in the model list: append its id here.
  keylessProviders = [
    "aihorde"
    "auggie"
    "cloudflare-playground"
    "devin-cli-agentic"
    "duckduckgo-web"
    "minimax-code"
    "uncloseai"
    "veoaifree-web"
    "zcode"
  ];

  settings = {
    modelVisibilityAllowlist = map (provider: "${provider}/*") providers;
    blockedProviders = keylessProviders;
    hideAutoCombos = true;
  };
in {
  den.aspects.services.omniroute = {user}: {
    includes = [den.aspects.virtualization.podman];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      home = config.users.users.${user.userName}.home;
      # ACP detects and spawns agent CLIs from PATH. The user's imperative `nix profile` holds them;
      # its links resolve through the shared store, so upgrades reach the container without a restart.
      profile = "${home}/.local/state/nix";
      quote = value: "'${lib.replaceStrings ["'"] ["''"] value}'";
      # OmniRoute keeps its settings as JSON rows and rereads them within a minute.
      seed = pkgs.writeText "omniroute-settings.sql" ''
        INSERT OR REPLACE INTO key_value (namespace, key, value) VALUES
        ${lib.concatStringsSep ",\n" (lib.mapAttrsToList (key: value: "  ('settings', ${quote key}, ${quote (builtins.toJSON value)})") settings)};
      '';
    in {
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0700 ${uid} ${uid} -"
        "d ${codexTokenDir} 0700 ${uid} ${uid} -"
      ];

      virtualisation.oci-containers.containers.omniroute = {
        inherit image pull;
        ports = ["127.0.0.1:${toString port}:${toString port}"];
        volumes = [
          "${dataDir}:/app/data"
          "/nix/store:/nix/store:ro"
          "${profile}:${profile}:ro"
          # The image's `node` shares the user's uid, so the CLIs reuse and refresh the host logins.
          "${home}/.claude:/home/node/.claude"
          "${home}/.codex:/home/node/.codex"
          "${codexTokenDir}:/run/codex-appserver:ro"
        ];
        environment = {
          # Empty: the dashboard's first-run wizard sets the password. The image generates its other
          # secrets into the data directory and requires an API key on /v1.
          INITIAL_PASSWORD = "";
          PATH = "${profile}/profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
          OMNIROUTE_CODEX_APPSERVER_WS = codexAppServer;
          OMNIROUTE_CODEX_APPSERVER_WS_TOKEN_FILE = "/run/codex-appserver/token";
        };
      };

      # The user's `codex app-server`, inside OmniRoute's network namespace so it stays on loopback.
      virtualisation.oci-containers.containers.omniroute-codex = {
        inherit image pull;
        dependsOn = ["omniroute"];
        extraOptions = ["--network=container:omniroute"];
        volumes = [
          "/nix/store:/nix/store:ro"
          "${profile}:${profile}:ro"
          "${home}/.codex:/home/node/.codex"
          "${codexTokenDir}:/run/codex-appserver"
        ];
        environment.CODEX_HOME = "/home/node/.codex";
        entrypoint = "/bin/sh";
        cmd = [
          "-c"
          ''
            token=/run/codex-appserver/token
            [ -s "$token" ] || node -e 'require("fs").writeFileSync(process.argv[1], require("crypto").randomBytes(32).toString("hex"), {mode: 0o600})' "$token"
            exec ${profile}/profile/bin/codex app-server --listen ${codexAppServer} --ws-auth capability-token --ws-token-file "$token"
          ''
        ];
      };
      # It lives in OmniRoute's network namespace, so it must restart with it.
      systemd.services.podman-omniroute-codex.partOf = ["podman-omniroute.service"];

      systemd.services.omniroute-settings = {
        description = "Apply the OmniRoute provider policy";
        after = ["podman-omniroute.service"];
        partOf = ["podman-omniroute.service"];
        wantedBy = ["podman-omniroute.service"];
        path = [pkgs.sqlite];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = uid;
          TimeoutStartSec = 300;
        };
        # OmniRoute refuses to boot from a database it did not create, so wait for its first migration.
        script = ''
          db=${dataDir}/storage.sqlite
          until [ -e "$db" ] && [ -n "$(sqlite3 "$db" "SELECT 1 FROM sqlite_master WHERE name = 'key_value'")" ]; do
            sleep 2
          done
          sqlite3 -cmd '.timeout 10000' "$db" < ${seed}
        '';
      };
    };
  };
}
