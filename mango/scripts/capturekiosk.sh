#!/bin/bash
# Runs `capture` (mpv capture-card feed) and closes it once focus leaves.
export CAPTURE_TITLE="video0"

capture --input-commands="keybind ESC quit" &

for i in $(seq 1 20); do
  win_id=$(mmsg get all-clients 2>/dev/null | jq -r '.clients[] | select(.title=="video0") | .id' | head -n1)
  [ -n "$win_id" ] && break
  sleep 0.2
done
[ -z "$win_id" ] && exit 0

while true; do
  sleep 0.2
  mmsg get client "$win_id" 2>/dev/null | jq -e '.error' >/dev/null && exit 0
  focused_id=$(mmsg get focusing-client 2>/dev/null | jq -r '.id // empty')
  if [ "$focused_id" = "$win_id" ]; then
    seen_focus=1
  elif [ -n "${seen_focus:-}" ]; then
    mmsg dispatch killclient client,"$win_id" >/dev/null
    exit 0
  fi
done
