#!/bin/bash
# Closes the Cog kiosk window once focus moves to anything else
info=$(~/.config/mango/scripts/findcog.sh) || exit 0
cog_id=$(jq -r '.id' <<<"$info")

seen=0
while IFS= read -r line; do
    jq -e 'has("error")' <<<"$line" >/dev/null 2>&1 && exit 0

    if [ "$(jq -r '.is_focused' <<<"$line")" = "true" ]; then
        seen=1
        continue
    fi
    if (( seen )); then
        mmsg dispatch killclient client,"$cog_id" >/dev/null
        exit 0
    fi
done < <(mmsg watch client "$cog_id")
