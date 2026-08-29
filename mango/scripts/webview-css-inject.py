#!/usr/bin/env python3
# Local reverse proxy that injects a CSS file into the proxied page's <head>,
# for theming kiosk webviews (cog has no built-in user-stylesheet support).
import sys
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TARGET, CSS_PATH, PORT = sys.argv[1], sys.argv[2], int(sys.argv[3])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
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
                body = body.replace(b"</head>", f"<style>{css}</style></head>".encode(), 1)
            except OSError:
                pass

        self.send_response(200)
        self.send_header("Content-Type", content_type or "application/octet-stream")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
