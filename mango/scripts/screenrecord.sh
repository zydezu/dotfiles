#!/usr/bin/env bash
MODE="$1"
BASE_DIR="$HOME/Videos/recordings"
DATE_DIR="$(date +'%Y-%m-%d')"
DIR="$BASE_DIR/$DATE_DIR"
mkdir -p "$DIR"
PIDFILE="/tmp/gpu-screen-recorder.pid"

# Get window names on current workspace for filename
get_workspace_name() {
    MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')

    BORING_APPIDS="org.gnome.Nautilus|thunar|org.kde.dolphin|pcmanfm|nemo"

    mmsg -g -c 2>/dev/null | awk -v mon="$MONITOR" -v boring="$BORING_APPIDS" '
        $1 == mon && $2 == "title"  { $1=$2=""; sub(/^ +/,""); title=$0 }
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

# STOP RECORDING
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE" | head -1)
    FILE=$(cat "$PIDFILE" | tail -1)
    if kill -0 "$PID" 2>/dev/null; then
        kill -INT "$PID"
        wait "$PID" 2>/dev/null
        rm -f "$PIDFILE"
        TMPDIR=$(mktemp -d)
        THUMB_FILE="$TMPDIR/thumb.png"
        ffmpeg -i "$FILE" -vframes 1 -vf "scale=128:128" -y "$THUMB_FILE" 2>/dev/null
        if [ -f "$THUMB_FILE" ]; then
            ACTION=$(dunstify "Recording has been saved" \
                -i "$THUMB_FILE" \
                -t 2000 \
                -A open,"Open Folder")
        else
            ACTION=$(dunstify "Recording has been saved" \
                -t 2000 \
                -A open,"Open Folder")
        fi
        [ "$ACTION" = "open" ] && xdg-open "$(dirname "$FILE")"
        (sleep 3 && rm -rf "$TMPDIR") &
        exit 0
    else
        rm -f "$PIDFILE"
    fi
fi

# START RECORDING
WORKSPACE_NAME=$(get_workspace_name)
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_${WORKSPACE_NAME}.mp4"
MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')

if [ "$MODE" = "select" ]; then
    GEOMETRY=$(slurp -f "%wx%h+%x+%y") || exit 1
    [ -z "$GEOMETRY" ] && exit 1
    gpu-screen-recorder \
        -w "region" \
        -region "$GEOMETRY" \
        -c mp4 \
        -f 60 \
        -a default_output \
        -k h264 \
        -q medium \
        -fm vfr \
        -o "$FILE" &
else
    gpu-screen-recorder \
        -w "$MONITOR" \
        -c mp4 \
        -f 60 \
        -a default_output \
        -k h264 \
        -q medium \
        -fm vfr \
        -o "$FILE" &
fi

PID=$!
echo -e "$PID\n$FILE" > "$PIDFILE"
ACTION=$(dunstify "Recording started" \
    -t 2000 \
    -A stop,"Stop Recording")
if [ "$ACTION" = "stop" ]; then
    kill -INT "$(cat "$PIDFILE" | head -1)"
    rm -f "$PIDFILE"
fi
