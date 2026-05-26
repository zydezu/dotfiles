#!/bin/bash
bluetui &
PID=$!
sleep 0.1
wtype -d 100 s
wtype -k Tab
wait $PID
