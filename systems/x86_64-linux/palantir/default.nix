{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.${namespace}) enabled;
  flakeDir = lib.${namespace}.flakeDir inputs;
  dashboardScript = pkgs.writeText "palantir-status-dashboard.py" ''
    import subprocess
    from http.server import BaseHTTPRequestHandler, HTTPServer
    from urllib.request import urlopen

    def probe(url):
        try:
            with urlopen(url, timeout=1) as response:
                return "healthy" if 200 <= response.status < 400 else "unhealthy"
        except Exception:
            return "unhealthy"

    def link(port, label):
        return f'<a href="https://palantir.tail3cc997.ts.net:{port}/">{label}</a>'

    class DashboardHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != "/":
                self.send_error(404)
                return
            hindsight = probe("http://127.0.0.1:8888/health")
            hermes = probe("http://127.0.0.1:8642/health")
            try:
                result = subprocess.run(
                    ["systemctl", "is-active", "hermes-link"],
                    capture_output=True,
                    text=True,
                    timeout=1,
                    check=False,
                )
                link_status = "healthy" if result.returncode == 0 else "unhealthy"
            except Exception:
                link_status = "unhealthy"
            rows = [
                ("Dashboard", "healthy", "8080", '<a href="/">this page</a>'),
                ("Hindsight UI", hindsight, "9999", link(8443, "open UI")),
                ("Hindsight API", hindsight, "8888", link(8444, "open API")),
                ("Hermes API", hermes, "8642", "not exposed"),
                ("Hermes Link", link_status, "52379", "not exposed"),
            ]
            body = "".join(
                f"<tr><td>{name}</td><td>{status}</td><td><code>{port}</code></td><td>{href}</td></tr>"
                for name, status, port, href in rows
            )
            page = f"""<!doctype html>
    <html lang="en"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Palantir services</title>
    <style>body {{ font: 1rem system-ui, sans-serif; margin: 2rem auto; max-width: 55rem; padding: 0 1rem; }}
    table {{ border-collapse: collapse; width: 100%; }} th, td {{ border-bottom: 1px solid #ddd; padding: .6rem; text-align: left; }}
    code {{ white-space: nowrap; }}</style></head><body><h1>Palantir services</h1>
    <table><thead><tr><th>Service</th><th>Status</th><th>Backend port</th><th>Tailnet link</th></tr></thead>
    <tbody>{body}</tbody></table></body></html>"""
            payload = page.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *_):
            pass

    HTTPServer(("127.0.0.1", 8080), DashboardHandler).serve_forever()
  '';
  tailscaleReadyCheck = pkgs.writeShellScript "palantir-tailscale-ready" ''
    for attempt in $(seq 1 30); do
      if ${pkgs.curl}/bin/curl --silent --fail http://127.0.0.1:8080/ >/dev/null &&
        ${config.services.tailscale.package}/bin/tailscale status --json 2>/dev/null |
          ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
        exit 0
      fi
      sleep 2
    done
    exit 1
  '';
in {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  ${namespace} = {
    system.boot.bios = enabled;
    system.boot.enable = lib.mkForce false;

    suites = {
      server.enable = true;
    };
    # suites.kubernetes = enabled;

    cli.programs.nix-ld = enabled;

    services = {
      hermes = {
        enable = true;
        browser = {
          enable = true;
          apiKeySecret = "browser_use_api_key";
        };
        settings = {
          browser.cloud_provider = "browser-use";
        };
      };
      hindsight = enabled;
      virtualisation.podman = enabled;
    };

    user."1" = {
      name = "alex";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };

  # Hindsight stays loopback-only; Serve is the only tailnet exposure.
  systemd.services.palantir-status-dashboard = {
    description = "Serve the Palantir service status dashboard";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python ${dashboardScript}";
      DynamicUser = true;
      Restart = "always";
      RestartSec = 2;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  systemd.services.tailscale-hindsight-serve = {
    description = "Expose Palantir services on the tailnet";
    wantedBy = ["multi-user.target"];
    after = [
      "tailscaled.service"
      "network-online.target"
      "palantir-status-dashboard.service"
      "podman-hindsight.service"
    ];
    wants = ["tailscaled.service" "network-online.target" "palantir-status-dashboard.service" "podman-hindsight.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = tailscaleReadyCheck;
      ExecStart = [
        "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --http=80 http://127.0.0.1:8080"
        "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=443 http://127.0.0.1:8080"
        "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=8443 http://127.0.0.1:9999"
        "${config.services.tailscale.package}/bin/tailscale serve --yes --bg --https=8444 http://127.0.0.1:8888"
      ];
      Restart = "on-failure";
      RestartSec = "15s";
    };
  };
  sops.secrets."ssh_private_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "600";
    path = "/home/" + config.${namespace}.user."1".name + "/.ssh/id_ed25519";
    sopsFile = flakeDir "secrets/hosts/palantir.yaml";
  };

  sops.secrets."ssh_public_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "644";
    path = "/home/" + config.${namespace}.user."1".name + "/.ssh/id_ed25519.pub";
    sopsFile = flakeDir "secrets/hosts/palantir.yaml";
  };

  environment.systemPackages = [pkgs.home-manager];

  programs.zsh.enable = true;

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "26.05";
  # ======================== DO NOT CHANGE THIS ========================
}
