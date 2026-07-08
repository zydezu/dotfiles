#!/bin/bash
exec >> /tmp/watch-kiosk.log 2>&1
echo "=== started $(date) ==="

cog_id=""
for i in $(seq 1 20); do
  cog_id=$(mmsg get all-clients | jq -r '.clients[] | select(.title=="Cog") | .id' | head -n1)
  if [ -n "$cog_id" ]; then
    echo "found cog_id: $cog_id after ${i}x0.2s"
    break
  fi
  sleep 0.2
done

if [ -z "$cog_id" ]; then
  echo "gave up waiting for cog window, exiting"
  exit 0
fi

stdbuf -oL mmsg watch focusing-client | while read -r line; do
  echo "event: $line"
  focused_id=$(echo "$line" | jq -r '.id // empty' 2>/dev/null)
  if [ -n "$focused_id" ] && [ "$focused_id" != "$cog_id" ]; then
    echo "focus moved to $focused_id, killing $cog_id"
    mmsg dispatch killclient client,"$cog_id"
    break
  fi
done
echo "=== exited $(date) ==="
