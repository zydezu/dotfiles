#!/bin/sh

prev_state=$(mmsg -g -m | awk '{print $NF}')

mmsg -w -m | while read -r line; do
    state=$(echo "$line" | awk '{print $NF}')

    if [ "$state" = "$prev_state" ]; then
        continue
    fi
    prev_state="$state"

    if [ "$state" = "1" ]; then
        swaync-client --inhibitor-add "fullscreen"
        swaync-client --dnd-on
    else
        swaync-client --inhibitor-remove "fullscreen"
        swaync-client --dnd-off
    fi
done
