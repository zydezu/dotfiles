#!/usr/bin/env bash
# Toggle the rofi launcher
set -euo pipefail

pidfile="${XDG_RUNTIME_DIR:-/run/user/$UID}/rofi.pid"
pid=""

if [[ -s $pidfile ]]; then
    IFS= read -r pid < "$pidfile" || true
    if [[ $pid =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        kill -INT "$pid" # same as Escape / Ctrl+C in rofi
        # Let it release its pidfile lock before a later tap can relaunch it.
        for _ in {1..20}; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.05
        done
        exit 0
    fi
fi

# A killed rofi leaves a stale pidfile that blocks the next launch.
rm -f "$pidfile"
exec rofi -modes drun -show drun -theme "$HOME/.config/rofi/config.rasi"
