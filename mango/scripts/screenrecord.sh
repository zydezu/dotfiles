#!/usr/bin/env bash
# Refer to 'man gpu-screen-recorder' for more details about these options
FPS=60 # The frame rate to record at
VIDEO_CODEC="hevc" # Recording codec, such as h264, hevc or av1
AUDIO_CODEC="opus" # The audio codec to use, it can be opus or aac
QUALITY="high" # Can be medium, high, very_high, ultra
ob
MODE="$1"
BASE_DIR="$HOME/Videos/recordings"
DATE_DIR="$(date +'%Y-%m-%d')"
DIR="$BASE_DIR/$DATE_DIR"
mkdir -p "$DIR"
PIDFILE="/tmp/gpu-screen-recorder.pid"

if mmsg get version >/dev/null 2>&1; then
    MMSG_NEW=1
else
    MMSG_NEW=0
fi

# Get window names on current workspace for filename
get_workspace_name() {
    BORING_APPIDS="org.gnome.Nautilus|thunar|org.kde.dolphin|pcmanfm|nemo"

    if (( MMSG_NEW )); then
        CLIENT=$(mmsg get focusing-client 2>/dev/null)
        [ -z "$CLIENT" ] && return
        APPID=$(printf '%s' "$CLIENT" | jq -r '.appid // ""')
        TITLE=$(printf '%s' "$CLIENT" | jq -r '.title // ""' | cut -c1-30)
        SHORTAPP=$(printf '%s\n' "$APPID" | awk -F. '{print $NF}')
        if printf '%s\n' "$APPID" | grep -qE "$BORING_APPIDS"; then
            printf '%s' "$SHORTAPP"
        else
            printf '%s %s' "$SHORTAPP" "$TITLE"
        fi
    else
        MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')
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
        '
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
        kill -INT "$PID"
        wait "$PID" 2>/dev/null
        rm -f "$PIDFILE"
        TMPDIR=$(mktemp -d)
        THUMB_FILE="$TMPDIR/thumb.png"
        ffmpeg -i "$FILE" -vframes 1 -vf "scale=128:128:force_original_aspect_ratio=increase,crop=128:128" -y "$THUMB_FILE" 2>/dev/null
        echo "file://$FILE" | wl-copy --type text/uri-list

        if [ -f "$THUMB_FILE" ]; then
            ACTION=$(dunstify "Screen recording has been saved" \
                -i "$THUMB_FILE" \
                -t 4000 \
                -A view,"View Recording" \
                -A open,"Open Folder")
        else
            ACTION=$(dunstify "Screen recording has been saved" \
                -t 4000 \
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
WORKSPACE_NAME=$(get_workspace_name)
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_${WORKSPACE_NAME}.mp4"
if (( MMSG_NEW )); then
    MONITOR=$(mmsg get all-monitors | jq -r '.monitors[] | select(.active == true) | .name' | head -1)
else
    MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')
fi

if [ "$MODE" = "select" ]; then
    GEOMETRY=$(slurp -f "%wx%h+%x+%y") || exit 1
    [ -z "$GEOMETRY" ] && exit 1
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
echo -e "$PID\n$FILE" > "$PIDFILE"
