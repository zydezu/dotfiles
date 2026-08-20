#!/bin/bash
# Closes the Cog kiosk window once focus moves to anything else. Polls
# instead of using `mmsg watch focusing-client`, since that stream can
# silently stall forever (found instances still blocked after 12+ hours).
info=$(~/.config/mango/scripts/findcog.sh) || exit 0
cog_id=$(echo "$info" | jq -r '.id')

while true; do
  sleep 0.2
  mmsg get client "$cog_id" 2>/dev/null | jq -e '.error' >/dev/null && exit 0
  focused_id=$(mmsg get focusing-client 2>/dev/null | jq -r '.id // empty')
  if [ "$focused_id" != "$cog_id" ]; then
    mmsg dispatch killclient client,"$cog_id" >/dev/null
    exit 0
  fi
done
