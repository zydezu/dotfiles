#!/usr/bin/env bash

MODE="$1"
DIR="$HOME/Pictures/screenshots"
mkdir -p "$DIR"

TMPDIR=$(mktemp -d)
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Take screenshot
if [ "$MODE" = "select" ]; then
    GEOMETRY=$(slurp) || { echo "Selection cancelled"; exit 1; }
    if [ -z "$GEOMETRY" ]; then
        echo "Selection cancelled"
        exit 1
    fi
    grim -g "$GEOMETRY" "$FILE" || { echo "Screenshot failed"; exit 1; }
elif [ "$MODE" = "both" ]; then
    grim "$FILE" || { echo "Screenshot failed"; exit 1; }
else
    MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')
    grim -o "$MONITOR" "$FILE" || { echo "Screenshot failed"; exit 1; }
fi

# Verify screenshot was created
if [ ! -f "$FILE" ]; then
    echo "Screenshot file not created: $FILE"
    exit 1
fi

# Copy to clipboard
wl-copy --type image/png < "$FILE"

# Create a temporary 1:1 image for the notification
CROPPED_FILE="$TMPDIR/cropped.png"
magick "$FILE" -gravity center -crop '%[fx:min(w,h)]x%[fx:min(w,h)]+0+0' -resize 128x128 +repage "$CROPPED_FILE"

if [ ! -f "$CROPPED_FILE" ]; then
    # Fallback to original file
    CROPPED_FILE="$FILE"
fi

ACTION=$(dunstify "Screenshot has been saved" \
    -i "$CROPPED_FILE" \
    -t 10000 \
    -A open,"Open Folder" \
    -A edit,"Edit Image" \
    -A delete,"Delete File")

if [ "$ACTION" = "edit" ]; then
    swappy -f "$FILE" &
elif [ "$ACTION" = "open" ]; then
    xdg-open "$(dirname "$FILE")" &
elif [ "$ACTION" = "delete" ]; then
    rm "$FILE"
fi

# Clean up temp directory after a short delay to allow notification to be displayed
(sleep 3 && rm -rf "$TMPDIR") &
