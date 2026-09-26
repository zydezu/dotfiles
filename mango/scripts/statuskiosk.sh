#!/bin/bash
PORT=47821
SERVERSTATUS_DIR=~/Projects/python/serverstatus
SERVERSTATUS_PORT=9090

(cd "$SERVERSTATUS_DIR" && exec python3 proxy.py --no-browser) &
backend_pid=$!

~/.config/mango/scripts/webview-css-inject.py "http://localhost:$SERVERSTATUS_PORT" ~/.config/matugen/generic-webview.css "$PORT" &
proxy_pid=$!
trap 'kill "$proxy_pid" "$backend_pid" 2>/dev/null' EXIT

for i in $(seq 1 20); do
  curl -s -o /dev/null "http://127.0.0.1:$SERVERSTATUS_PORT/" && break
done

for i in $(seq 1 20); do
  curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break
done

cog --platform=x11 "http://127.0.0.1:$PORT/?dark_mode=1" &
~/.config/mango/scripts/watchkiosk.sh
