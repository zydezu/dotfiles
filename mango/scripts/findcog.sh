#!/bin/bash
# Prints the mmsg JSON for the "Cog" client, waiting up to ~4s for it to
# map. Prints nothing (and exits 1) if it never appears. Shared by
# watchkiosk.sh and movecogwin.sh so both target the same window.
for i in $(seq 1 20); do
  info=$(mmsg get all-clients | jq -c '.clients[] | select(.title=="Cog")' | head -n1)
  if [ -n "$info" ]; then
    echo "$info"
    exit 0
  fi
  sleep 0.2
done
exit 1
