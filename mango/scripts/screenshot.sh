#!/usr/bin/env bash
MODE="$1"
BASE_DIR="$HOME/Pictures/screenshots"
DATE_DIR="$(date +'%Y-%m-%d')"
DIR="$BASE_DIR/$DATE_DIR"
mkdir -p "$DIR"
TMPDIR=$(mktemp -d)

tick() { date +%s%3N; }
tock() { printf '[%s] %dms\n' "$1" "$(($(tick) - $2))"; }

# Get window names on current workspace for filename
get_workspace_name() {
    BORING_APPIDS="org.gnome.Nautilus|thunar|org.kde.dolphin|pcmanfm|nemo"
    CLIENT=$(mmsg get focusing-client 2>/dev/null)
    [ -z "$CLIENT" ] && return
    { read -r APPID; read -r TITLE; } < <(printf '%s' "$CLIENT" | jq -r '.appid // "", (.title // "")[:30]')
    SHORTAPP=$(printf '%s\n' "$APPID" | awk -F. '{print $NF}')
    if printf '%s\n' "$APPID" | grep -qE "$BORING_APPIDS"; then
        printf '%s' "$SHORTAPP"
    else
        printf '%s %s' "$SHORTAPP" "$TITLE"
    fi \
    | tr -cs 'a-zA-Z0-9-' '_' \
    | sed 's/__*/_/g; s/^_//; s/_$//' \
    | tr '[:upper:]' '[:lower:]'
}

_t=$(tick); WORKSPACE_NAME=$(get_workspace_name); tock "workspace_name" $_t
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_${WORKSPACE_NAME}.png"

# Take screenshot
if [ "$MODE" = "select" ]; then
    PIPE=$(mktemp -u)
    mkfifo "$PIPE"
    wayfreeze --hide-cursor --after-freeze-cmd "echo > $PIPE" & # hide cursor doesn't work
    WAYFREEZE_PID=$!
    read -r < "$PIPE"
    GEOMETRY=$(slurp) || { kill "$WAYFREEZE_PID" 2>/dev/null; rm -f "$PIPE"; exit 1; }
    rm -f "$PIPE"
    if [ -z "$GEOMETRY" ]; then
        kill "$WAYFREEZE_PID" 2>/dev/null
        echo "Selection cancelled"
        exit 1
    fi
    _t=$(tick)
    grim -g "$GEOMETRY" "$FILE" || { echo "Screenshot failed"; kill "$WAYFREEZE_PID" 2>/dev/null; exit 1; }
    tock "grim" $_t
    kill "$WAYFREEZE_PID" 2>/dev/null
elif [ "$MODE" = "both" ]; then
    _t=$(tick)
    grim "$FILE" || { echo "Screenshot failed"; exit 1; }
    tock "grim" $_t
else
    _t=$(tick)
    MONITOR=$(mmsg get all-monitors | jq -r '.monitors[] | select(.active == true) | .name' | head -1)
    tock "monitor" $_t
    _t=$(tick)
    grim -o "$MONITOR" "$FILE" || { echo "Screenshot failed"; exit 1; }
    tock "grim" $_t
fi

# Verify screenshot was created
if [ ! -f "$FILE" ]; then
    echo "Screenshot file not created: $FILE"
    exit 1
fi

# Copy to clipboard in background while generating thumbnail
wl-copy --type image/png < "$FILE" &

_t=$(tick)
CROPPED_FILE="$TMPDIR/cropped.png"
magick "$FILE" -thumbnail 128x128^ -gravity center -extent 128x128 "$CROPPED_FILE"
tock "magick" $_t

if [ ! -f "$CROPPED_FILE" ]; then
    CROPPED_FILE="$FILE"
fi

ACTION=$(dunstify "Screenshot has been saved" \
    -i "$CROPPED_FILE" \
    -t 2000 \
    -A view,"View Image" \
    -A edit,"Annotate" \
    -A open,"Open Folder")

[ "$ACTION" = "view" ] && xdg-open "$FILE" &
[ "$ACTION" = "open" ] && xdg-open "$(dirname "$FILE")" &
[ "$ACTION" = "edit" ] && swappy -f "$FILE" &

# Clean up temp directory to allow notification to be displayed
(sleep 3 && rm -rf "$TMPDIR") &
