#!/bin/bash
# stupid hack stupid hack stupid hack, cant name cog window. stupid hack
w="$1"
h="$2"

info=$(~/.config/mango/scripts/findcog.sh) || exit 0
IFS=$'\t' read -r cog_id old_x old_w < <(jq -r '[.id, .x, .width] | @tsv' <<<"$info")

mmsg dispatch resizewin,"$w","$h" client,"$cog_id"
mmsg dispatch movewin,"$((old_x - (w - old_w)))",+0 client,"$cog_id"
