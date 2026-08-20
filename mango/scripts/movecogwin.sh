#!/bin/bash
# mango only evaluates windowrule appid/title matching once, at map time,
# and cog never sets WM_CLASS -- so appid-based rules can't single out one
# cog kiosk from another. The shared title:Cog rule already right-anchors
# every cog window via offsetx:100 (computed for the rule's default
# width). resizewin only grows geom.width -- it doesn't recompute x -- so
# widening the window pushes its right edge further right, potentially
# off the monitor. Re-anchor x by the same delta after resizing so the
# right edge stays where offsetx:100 put it.
w="$1"
h="$2"

info=$(~/.config/mango/scripts/findcog.sh) || exit 0
cog_id=$(echo "$info" | jq -r '.id')
old_x=$(echo "$info" | jq -r '.x')
old_w=$(echo "$info" | jq -r '.width')

mmsg dispatch resizewin,"$w","$h" client,"$cog_id"
mmsg dispatch movewin,"$((old_x - (w - old_w)))",+0 client,"$cog_id"
