{pkgs}:
pkgs.writeText "palantir-status-dashboard.py" ''
  import secrets
  import subprocess
  from http.server import BaseHTTPRequestHandler, HTTPServer
  from pathlib import Path
  from urllib.parse import parse_qs
  from urllib.request import urlopen

  RESTART_TOKEN = secrets.token_urlsafe(32)
  RESTART_TRIGGER = Path("/run/palantir-status-dashboard/restart-hermes-link")

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
              result = subprocess.run(["systemctl", "is-active", "hermes-link"], capture_output=True, timeout=1, check=False)
              link_status = "running (relay unchecked)" if result.returncode == 0 else "unhealthy"
          except Exception:
              link_status = "unhealthy"
          rows = [
              ("Dashboard", "healthy", "8080", '<a href="/">this page</a>'),
              ("Hindsight UI", hindsight, "9999", link(8443, "open UI")),
              ("Hindsight API", hindsight, "8888", link(8444, "open API")),
              ("Hermes API", hermes, "8642", "not exposed"),
              ("Hermes Link", link_status, "52379", "not exposed"),
          ]
          body = "".join(f"<tr><td>{name}</td><td>{status}</td><td><code>{port}</code></td><td>{href}</td></tr>" for name, status, port, href in rows)
          page = f'''<!doctype html>
  <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Palantir services</title>
  <style>body {{ font: 1rem system-ui, sans-serif; margin: 2rem auto; max-width: 55rem; padding: 0 1rem; }} table {{ border-collapse: collapse; width: 100%; }} th, td {{ border-bottom: 1px solid #ddd; padding: .6rem; text-align: left; }} code {{ white-space: nowrap; }} button {{ font: inherit; margin-top: 1rem; padding: .6rem; }}</style></head>
  <body><h1>Palantir services</h1><table><thead><tr><th>Service</th><th>Status</th><th>Backend port</th><th>Tailnet link</th></tr></thead><tbody>{body}</tbody></table>
  <form method="post" action="/restart-hermes-link" onsubmit="return confirm('Restart Hermes Link?')"><input type="hidden" name="csrf" value="{RESTART_TOKEN}"><button type="submit">Restart Hermes Link</button></form></body></html>'''
          payload = page.encode()
          self.send_response(200)
          self.send_header("Content-Type", "text/html; charset=utf-8")
          self.send_header("Cache-Control", "no-store")
          self.send_header("Content-Length", str(len(payload)))
          self.end_headers()
          self.wfile.write(payload)

      def do_POST(self):
          if self.path != "/restart-hermes-link":
              self.send_error(404)
              return
          try:
              length = int(self.headers.get("Content-Length", "0"))
          except ValueError:
              self.send_error(400)
              return
          if not 0 < length <= 1024:
              self.send_error(400)
              return
          try:
              form = parse_qs(self.rfile.read(length).decode("ascii"), strict_parsing=True)
          except (UnicodeDecodeError, ValueError):
              self.send_error(400)
              return
          if not secrets.compare_digest(form.get("csrf", [""])[0], RESTART_TOKEN):
              self.send_error(403)
              return
          try:
              RESTART_TRIGGER.touch()
          except OSError:
              self.send_error(503)
              return
          payload = b"<!doctype html><title>Restart requested</title><p>Hermes Link restart requested.</p>"
          self.send_response(202)
          self.send_header("Content-Type", "text/html; charset=utf-8")
          self.send_header("Content-Length", str(len(payload)))
          self.send_header("Cache-Control", "no-store")
          self.send_header("Refresh", "2; url=/")
          self.end_headers()
          self.wfile.write(payload)

      def log_message(self, *_):
          pass

  HTTPServer(("127.0.0.1", 8080), DashboardHandler).serve_forever()
''
