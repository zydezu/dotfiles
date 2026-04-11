#!/usr/bin/env bash
MODE="$1"
DIR="$HOME/Videos/recordings"
mkdir -p "$DIR"
PIDFILE="/tmp/gpu-screen-recorder.pid"

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
            ACTION=$(dunstify "Recording stopped" \
                -i "$THUMB_FILE" \
                -t 2000 \
                -A open,"Open Folder")
        else
            ACTION=$(dunstify "Recording stopped" \
                -t 2000 \
                -A open,"Open Folder")
        fi
        [ "$ACTION" = "open" ] && xdg-open "$DIR"
        (sleep 3 && rm -rf "$TMPDIR") &
        exit 0
    else
        rm -f "$PIDFILE"
    fi
fi

# START RECORDING
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"
MONITOR=$(mmsg -g -o | grep 'selmon 1' | awk '{print $1}')

if [ "$MODE" = "select" ]; then
    GEOMETRY=$(slurp -f "%wx%h+%x+%y") || exit 1
    [ -z "$GEOMETRY" ] && exit 1

    gpu-screen-recorder \
        -w "region" \
        -region "$GEOMETRY" \
        -f 60 \
        -fm cfr \
        -c mp4 \
        -a default_output \
        -o "$FILE" &
else
    gpu-screen-recorder \
        -w "$MONITOR" \
        -f 60 \
        -fm cfr \
        -c mp4 \
        -a default_output \
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
