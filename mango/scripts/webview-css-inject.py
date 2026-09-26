#!/usr/bin/env python3
# Local reverse proxy that injects a CSS file into the proxied page's <head>,
# for theming kiosk webviews (cog has no built-in user-stylesheet support).
import json
import subprocess
import sys
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TARGET, CSS_PATH, PORT = sys.argv[1], sys.argv[2], int(sys.argv[3])
CLOSE_PATH = "/__kiosk_close"
# Cog has no keybinds, so Escape is caught in-page and relayed here to kill the window
ESC_JS = (
    "<script>addEventListener('keydown',e=>{if(e.key==='Escape')"
    f"fetch('{CLOSE_PATH}')}},true)</script>"
)


def close_cog():
    out = subprocess.run(["mmsg", "get", "focusing-client"], capture_output=True, text=True).stdout
    try:
        client = json.loads(out)
    except ValueError:
        return
    if client.get("title") == "Cog":
        subprocess.run(["mmsg", "dispatch", "killclient", "client," + str(client["id"])])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path == CLOSE_PATH:
            close_cog()
            self.send_response(204)
            self.end_headers()
            return

        req = urllib.request.Request(
            TARGET.rstrip("/") + self.path, headers={"User-Agent": "Mozilla/5.0"}
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                body = resp.read()
                content_type = resp.headers.get("Content-Type", "")
        except Exception as e:
            self.send_error(502, str(e))
            return

        if "text/html" in content_type:
            try:
                with open(CSS_PATH) as f:
                    css = f.read()
            except OSError:
                css = ""
            body = body.replace(b"</head>", f"<style>{css}</style>{ESC_JS}</head>".encode(), 1)

        self.send_response(200)
        self.send_header("Content-Type", content_type or "application/octet-stream")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
