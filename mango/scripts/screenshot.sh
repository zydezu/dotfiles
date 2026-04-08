#!/usr/bin/env bash

# Screenshot mode: "full" or "select"
MODE="$1"
DIR="$HOME/Pictures/screenshots"
mkdir -p "$DIR"

# Create timestamped file
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Take screenshot
if [ "$MODE" = "select" ]; then
    grim -g "$(slurp)" "$FILE"
else
    grim "$FILE"
fi

# Copy to clipboard
wl-copy --type image/png < "$FILE"

# Send notification with "Edit" action to open in Swappy
ACTION=$(dunstify "Screenshot taken and copied to clipboard" \
    -A open,"Open" \
    -A edit,"Edit" \
    -A delete,"Delete")

if [ "$ACTION" = "edit" ]; then
    swappy -f "$FILE" &
elif [ "$ACTION" = "open" ]; then
    xdg-open "$(dirname "$FILE")" &
elif [ "$ACTION" = "delete" ]; then
    rm "$FILE"
fi
