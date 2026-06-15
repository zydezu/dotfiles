#!/bin/bash

is_dnd() {
    [[ "$(swaync-client --get-dnd 2>/dev/null)" == "true" ]]
}

dnd_active=0
was_manual_dnd=0

handle_fullscreen() {
    local is_any_fs=$1  # "true" or "false"

    if [[ "$is_any_fs" == "true" ]]; then
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

clients_any_fullscreen() {
    printf '%s' "$1" | jq -r 'if ([.clients[] | select(.is_fullscreen == true)] | length) > 0 then "true" else "false" end'
}

initial=$(mmsg get all-clients 2>/dev/null)
handle_fullscreen "$(clients_any_fullscreen "$initial")"

while IFS= read -r line; do
    handle_fullscreen "$(clients_any_fullscreen "$line")"
done < <(mmsg watch all-clients)
