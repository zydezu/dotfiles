#!/bin/bash

SECONDARY="DP-2"

# Switch monitor to HDMI
ddcutil setvcp 60 0x11 --display 1

MONITORS=$(mmsg get all-monitors)

# Focus secondary monitor if not already there
FOCUSED=$(jq -r '.monitors[] | select(.active == true) | .name' <<<"$MONITORS")
if [ "$FOCUSED" != "$SECONDARY" ]; then
    mmsg dispatch focusmon,left
fi

# Find first empty tag on secondary monitor
EMPTY_TAG=$(jq -r '.monitors[] | select(.name == "DP-2") | .tags[] | select(.client_count == 0) | .index' <<<"$MONITORS" | head -1)

if [ -z "$EMPTY_TAG" ]; then
    echo "No empty tags available on $SECONDARY" >&2
    exit 1
fi

# Switch to the empty tag for where OBS will go
mmsg dispatch view,"$EMPTY_TAG",0

obs &
