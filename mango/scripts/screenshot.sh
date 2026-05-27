#!/usr/bin/env bash
MODE="$1"
BASE_DIR="$HOME/Pictures/screenshots"
DATE_DIR="$(date +'%Y-%m-%d')"
DIR="$BASE_DIR/$DATE_DIR"
mkdir -p "$DIR"
TMPDIR=$(mktemp -d)

# Get window names on current workspace for filename
get_workspace_name() {
    MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')

    BORING_APPIDS="org.gnome.Nautilus|thunar|org.kde.dolphin|pcmanfm|nemo"

    mmsg -g -c 2>/dev/null | awk -v mon="$MONITOR" -v boring="$BORING_APPIDS" '
        $1 == mon && $2 == "title"  { $1=$2=""; sub(/^ +/,""); title=substr($0,1,30) }
        $1 == mon && $2 == "appid"  {
            appid = $3
            n = split(appid, parts, ".")
            shortapp = parts[n]

            if (appid ~ boring) print shortapp
            else print shortapp " " title
            exit
        }
    ' \
    | tr -cs 'a-zA-Z0-9-' '_' \
    | sed 's/__*/_/g; s/^_//; s/_$//' \
    | tr '[:upper:]' '[:lower:]'
}

WORKSPACE_NAME=$(get_workspace_name)
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_${WORKSPACE_NAME}.png"

# Take screenshot
if [ "$MODE" = "select" ]; then
    PIPE=$(mktemp -u)
    mkfifo "$PIPE"
    wayfreeze --hide-cursor --after-freeze-cmd "echo > $PIPE" &
    WAYFREEZE_PID=$!
    read -r < "$PIPE"
    GEOMETRY=$(slurp) || { kill "$WAYFREEZE_PID" 2>/dev/null; rm -f "$PIPE"; exit 1; }
    rm -f "$PIPE"
    if [ -z "$GEOMETRY" ]; then
        kill "$WAYFREEZE_PID" 2>/dev/null
        echo "Selection cancelled"
        exit 1
    fi
    grim -g "$GEOMETRY" "$FILE" || { echo "Screenshot failed"; kill "$WAYFREEZE_PID" 2>/dev/null; exit 1; }
    kill "$WAYFREEZE_PID" 2>/dev/null
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
    -t 4000 \
    -A view,"View Image" \
    -A edit,"Annotate" \
    -A open,"Open Folder")

[ "$ACTION" = "view" ] && xdg-open "$FILE" &
[ "$ACTION" = "open" ] && xdg-open "$(dirname "$FILE")" &
[ "$ACTION" = "edit" ] && swappy -f "$FILE" &

# Clean up temp directory to allow notification to be displayed
(sleep 3 && rm -rf "$TMPDIR") &
