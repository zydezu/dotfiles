#!/bin/bash
# Runs `capture` (mpv capture-card feed) and closes it once focus leaves.
export CAPTURE_TITLE="video0"

capture --input-commands="keybind ESC quit" &

# Bounded wait for the window to map
win_id=""
for _ in {1..20}; do
    win_id=$(mmsg get all-clients 2>/dev/null |
        jq -r 'first(.clients[] | select(.title == "video0") | .id) // empty')
    [ -n "$win_id" ] && break
    sleep 0.2
done
[ -z "$win_id" ] && exit 0

seen_focus=0
while IFS= read -r line; do
    jq -e 'has("error")' <<<"$line" >/dev/null 2>&1 && exit 0

    if [ "$(jq -r '.is_focused' <<<"$line")" = "true" ]; then
        seen_focus=1
        continue
    fi
    if (( seen_focus )); then
        mmsg dispatch killclient client,"$win_id" >/dev/null
        exit 0
    fi
done < <(mmsg watch client "$win_id")
