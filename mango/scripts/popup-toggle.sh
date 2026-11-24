#!/usr/bin/env bash
# Open/close a TUI popup from waybar/swaync and arm focus-loss autohide.
# Usage: popup-toggle.sh <key>   (key = appid or window title)
set -u

key=${1:-}
[[ -n $key ]] || exit 2

dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

case $key in
    clipse) cmd=(alacritty --class clipse --title clipse -e clipse) ;;
    wiremix) cmd=(alacritty --class wiremix --title wiremix -e wiremix) ;;
    btop) cmd=(alacritty --title btop -e btop) ;;
    wlctl) cmd=(alacritty --title wlctl -e wlctl) ;;
    bluetui) cmd=(alacritty --title bluetui -e "$HOME/.config/mango/waybar/scripts/openbluetui.sh") ;;
    storagetui) cmd=(alacritty --title storagetui -e "$HOME/.config/mango/waybar/scripts/openstoragetui.sh") ;;
    controller_viewer.py) cmd=("$HOME/Projects/python/controller-viewer/.venv/bin/python" "$HOME/Projects/python/controller-viewer/controller_viewer.py") ;;
    *) echo "unknown popup: $key" >&2; exit 2 ;;
esac

id=$(mmsg get all-clients 2>/dev/null |
    jq -r --arg k "$key" 'first(.clients[] | select(.appid == $k or .title == $k) | .id) // empty')

if [[ -n $id ]]; then
    mmsg dispatch killclient,force client,"$id" >/dev/null
else
    "${cmd[@]}" >/dev/null 2>&1 &
fi

setsid "$dir/window-autohide.sh" "$key" >/dev/null 2>&1 < /dev/null &
