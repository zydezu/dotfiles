#!/bin/bash
# stupid hack stupid hack stupid hack, cant name cog window. stupid hack
w="$1"
h="$2"

info=$(~/.config/mango/scripts/findcog.sh) || exit 0
cog_id=$(echo "$info" | jq -r '.id')
old_x=$(echo "$info" | jq -r '.x')
old_w=$(echo "$info" | jq -r '.width')

mmsg dispatch resizewin,"$w","$h" client,"$cog_id"
mmsg dispatch movewin,"$((old_x - (w - old_w)))",+0 client,"$cog_id"
