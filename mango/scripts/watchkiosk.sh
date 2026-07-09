#!/bin/bash

cog_id=""
for i in $(seq 1 20); do
  cog_id=$(mmsg get all-clients | jq -r '.clients[] | select(.title=="Cog") | .id' | head -n1)
  if [ -n "$cog_id" ]; then
    break
  fi
  sleep 0.2
done

if [ -z "$cog_id" ]; then
  exit 0
fi

stdbuf -oL mmsg watch focusing-client | while read -r line; do
  focused_id=$(echo "$line" | jq -r '.id // empty' 2>/dev/null)
  if [ -n "$focused_id" ] && [ "$focused_id" != "$cog_id" ]; then
    mmsg dispatch killclient client,"$cog_id"
    break
  fi
done
