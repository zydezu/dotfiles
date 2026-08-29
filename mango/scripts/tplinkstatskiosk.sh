#!/bin/bash
PORT=47822
~/.config/mango/scripts/webview-css-inject.py http://sunny:8090 ~/.config/matugen/generic-webview.css "$PORT" &
proxy_pid=$!
trap 'kill "$proxy_pid" 2>/dev/null' EXIT

for i in $(seq 1 20); do
  curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break
done

cog --platform=x11 "http://127.0.0.1:$PORT/?kiosk=1" &
~/.config/mango/scripts/movecogwin.sh 700 765
~/.config/mango/scripts/watchkiosk.sh
