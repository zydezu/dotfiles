#!/usr/bin/env bash
# Refer to 'man gpu-screen-recorder' for more details about these options
FPS=60 # The frame rate to record at
VIDEO_CODEC="hevc" # Recording codec, such as h264, hevc or av1
AUDIO_CODEC="opus" # The audio codec to use, it can be opus or aac
QUALITY="high" # Can be medium, high, very_high, ultra
MODE="$1"
BASE_DIR="$HOME/Videos/recordings"
DATE_DIR="$(date +'%Y-%m-%d')"
DIR="$BASE_DIR/$DATE_DIR"
mkdir -p "$DIR"
PIDFILE="/tmp/gpu-screen-recorder.pid"

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

# Stop and save recording
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE" | head -1)
    FILE=$(cat "$PIDFILE" | tail -1)
    if kill -0 "$PID" 2>/dev/null; then
        _total=$(tick)
        echo "stopping recording..."
        _t=$(tick)
        kill -INT "$PID"
        wait "$PID" 2>/dev/null
        tock "flush" $_t
        rm -f "$PIDFILE"
        TMPDIR=$(mktemp -d)
        THUMB_FILE="$TMPDIR/thumb.png"

        # Copy to clipboard in background while generating thumbnail
        echo "file://$FILE" | wl-copy --type text/uri-list &

        _t=$(tick)
        ffmpeg -i "$FILE" -vframes 1 -vf "scale=128:128:force_original_aspect_ratio=increase,crop=128:128" -y "$THUMB_FILE" 2>/dev/null
        tock "ffmpeg" $_t

        printf 'recording saved in %dms\n' "$(($(tick) - _total))"

        if [ -f "$THUMB_FILE" ]; then
            ACTION=$(dunstify "Screen recording has been saved" \
                -i "$THUMB_FILE" \
                -t 2000 \
                -A view,"View Recording" \
                -A open,"Open Folder")
        else
            ACTION=$(dunstify "Screen recording has been saved" \
                -t 2000 \
                -A view,"View Recording" \
                -A open,"Open Folder")
        fi

        [ "$ACTION" = "view" ] && xdg-open "$FILE"
        [ "$ACTION" = "open" ] && xdg-open "$(dirname "$FILE")"

        # Clean up temp directory to allow notification to be displayed
        (sleep 3 && rm -rf "$TMPDIR") &
        exit 0
    else
        rm -f "$PIDFILE"
    fi
fi

# Start recording
_total=$(tick)
echo "starting recording..."

if [ "$MODE" = "select" ]; then
    GEOMETRY=$(slurp -f "%wx%h+%x+%y") || exit 1
    [ -z "$GEOMETRY" ] && exit 1
    REGION_SIZE="${GEOMETRY%%+*}"
    FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_${REGION_SIZE}.mp4"
    gpu-screen-recorder \
        -w "region" \
        -region "$GEOMETRY" \
        -c mp4 \
        -f "$FPS" \
        -a default_output \
        -ac "$AUDIO_CODEC" \
        -k "$VIDEO_CODEC" \
        -q "$QUALITY" \
        -o "$FILE" &
else
    # Start workspace name lookup in background while querying monitor
    _wn_tmp=$(mktemp)
    get_workspace_name > "$_wn_tmp" &
    _wn_pid=$!

    _t=$(tick)
    MONITOR=$(mmsg get all-monitors | jq -r '.monitors[] | select(.active == true) | .name' | head -1)
    tock "monitor" $_t

    _t=$(tick)
    wait $_wn_pid
    WORKSPACE_NAME=$(cat "$_wn_tmp")
    rm -f "$_wn_tmp"
    tock "workspace_name" $_t

    FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_${WORKSPACE_NAME}.mp4"
    gpu-screen-recorder \
        -w "$MONITOR" \
        -c mp4 \
        -f "$FPS" \
        -a default_output \
        -ac "$AUDIO_CODEC" \
        -k "$VIDEO_CODEC" \
        -q "$QUALITY" \
        -o "$FILE" &
fi

PID=$!
printf 'recording started in %dms\n' "$(($(tick) - _total))"
echo -e "$PID\n$FILE" > "$PIDFILE"
