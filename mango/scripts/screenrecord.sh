#!/usr/bin/env bash
MODE="$1"
DIR="$HOME/Videos/recordings"
mkdir -p "$DIR"
PIDFILE="/tmp/gpu-screen-recorder.pid"

# STOP RECORDING
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill -INT "$PID"
        wait "$PID" 2>/dev/null
        rm "$PIDFILE"
        ACTION=$(dunstify "Recording stopped" \
            -t 2000 \
            -A open,"Open Folder")
        [ "$ACTION" = "open" ] && xdg-open "$DIR"
        exit 0
    else
        rm "$PIDFILE"
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
echo "$PID" > "$PIDFILE"

ACTION=$(dunstify "Recording started" \
    -t 2000 \
    -A stop,"Stop Recording")
if [ "$ACTION" = "stop" ]; then
    kill -INT "$(cat "$PIDFILE")"
    rm "$PIDFILE"
fi
