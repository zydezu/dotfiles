#!/bin/bash
if pgrep -f "controller_viewer.py" > /dev/null; then
    exit 0
fi
~/Projects/python/controller-viewer/.venv/bin/python ~/Projects/python/controller-viewer/controller_viewer.py &
disown
