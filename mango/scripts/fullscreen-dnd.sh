#!/bin/bash

declare -A monitor_state

while IFS= read -r line; do
    monitor_state[${line%% *}]=${line##* }
done < <(mmsg -g -m)

any_fullscreen() {
    for state in "${monitor_state[@]}"; do
        [[ "$state" == "1" ]] && return 0
    done
    return 1
}

is_dnd() {
    [[ "$(swaync-client --get-dnd 2>/dev/null)" == "true" ]]
}

dnd_active=0
was_manual_dnd=0

while IFS= read -r line; do
    monitor_state[${line%% *}]=${line##* }

    if any_fullscreen; then
        if (( dnd_active == 0 )); then
            if is_dnd; then
                was_manual_dnd=1
            else
                was_manual_dnd=0
                swaync-client --inhibitor-add "fullscreen"
                swaync-client --dnd-on
            fi
            dnd_active=1
        fi
    else
        if (( dnd_active == 1 )); then
            if (( was_manual_dnd == 0 )); then
                swaync-client --inhibitor-remove "fullscreen"
                swaync-client --dnd-off
            fi
            dnd_active=0
            was_manual_dnd=0
        fi
    fi
done < <(mmsg -w -m)
