#!/usr/bin/env bash
# Close a popup window when focus moves away from it.
# Usage: window-autohide.sh <appid-or-title>
#
# Works for any window (named scratchpad or not). Mango pushes focus events
# globally via `watch focusing-client`, so this is event-driven, not polling.

set -u

key=${1:-}
[[ -n $key ]] || exit 2

runtime=${XDG_RUNTIME_DIR:-/run/user/$UID}
lockfile="$runtime/window-autohide-${key//\//_}.lock"

# Replace a watcher left over from a previous open.
if [[ -s $lockfile ]]; then
    oldpid=$(<"$lockfile")
    if [[ $oldpid =~ ^[0-9]+$ ]] && kill -0 "$oldpid" 2>/dev/null; then
        kill "$oldpid" 2>/dev/null
    fi
fi
printf '%s\n' "$$" > "$lockfile"
trap 'rm -f "$lockfile"' EXIT

find_id() {
    mmsg get all-clients 2>/dev/null |
        jq -r --arg k "$key" 'first(.clients[] | select(.appid == $k or .title == $k) | .id) // empty'
}

id=""
for _ in {1..30}; do
    id=$(find_id)
    [[ -n $id ]] && break
    sleep 0.2
done
[[ -n $id ]] || exit 0

now_ms() {
    local s=${EPOCHREALTIME%%.*} f=${EPOCHREALTIME#*.}
    f="${f}000"
    printf '%s%s' "$s" "${f:0:3}"
}

close_popup() {
    info=$(mmsg get client "$id" 2>/dev/null) || exit 0
    jq -e 'has("error")' <<<"$info" >/dev/null 2>&1 && exit 0
    [[ $(jq -r '.is_visible' <<<"$info") == "true" ]] || exit 0
    mmsg dispatch killclient,force client,"$id" >/dev/null
    exit 0
}

opened=$(now_ms)
prev=""
focus_since=""
while IFS= read -r line; do
    focused=$(jq -r '.id // empty' <<<"$line")

    # focusing-client also fires on title/state updates for the same client.
    # Only act when the focused client actually changes.
    if [[ -z $prev ]]; then
        prev=$focused
        continue
    fi
    [[ $focused == "$prev" ]] && continue
    prev=$focused

    if [[ $focused == "$id" ]]; then
        [[ -z $focus_since ]] && focus_since=$(now_ms)
        continue
    fi

    # Focused at some point: close on the next focus change, ignoring the
    # brief bounce that happens right as the window maps.
    if [[ -n $focus_since ]]; then
        if (( $(now_ms) - focus_since >= 80 )); then
            close_popup
        fi
        focus_since=""
        continue
    fi

    # Never focused: brief grace, then a focus change is click-off.
    (( $(now_ms) - opened >= 200 )) || continue
    close_popup
done < <(mmsg watch focusing-client)
