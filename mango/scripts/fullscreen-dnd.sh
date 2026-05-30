#!/bin/bash

declare -A monitor_state

if mmsg get version >/dev/null 2>&1; then
    MMSG_NEW=1
else
    MMSG_NEW=0
fi

any_fullscreen() {
    for state in "${monitor_state[@]}"; do
        [[ "$state" == "true" || "$state" == "1" ]] && return 0
    done
    return 1
}

is_dnd() {
    [[ "$(swaync-client --get-dnd 2>/dev/null)" == "true" ]]
}

dnd_active=0
was_manual_dnd=0

handle_state_change() {
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
}

if (( MMSG_NEW )); then
    while IFS= read -r mon; do
        name=$(printf '%s' "$mon" | jq -r '.name')
        fs=$(printf '%s' "$mon" | jq -r '.fullscreen // false')
        monitor_state["$name"]=$fs
    done < <(mmsg get all-monitors | jq -c '.[]')

    while IFS= read -r line; do
        while IFS= read -r mon; do
            name=$(printf '%s' "$mon" | jq -r '.name')
            fs=$(printf '%s' "$mon" | jq -r '.fullscreen // false')
            monitor_state["$name"]=$fs
        done < <(printf '%s' "$line" | jq -c '.[]')
        handle_state_change
    done < <(mmsg watch all-monitors)
else
    while IFS= read -r line; do
        monitor_state[${line%% *}]=${line##* }
    done < <(mmsg -g -m)

    while IFS= read -r line; do
        monitor_state[${line%% *}]=${line##* }
        handle_state_change
    done < <(mmsg -w -m)
fi
