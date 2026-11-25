#!/bin/bash

DEVICE=$(upower -e | grep 'battery_ps_controller' | head -n1)

if [ -z "$DEVICE" ]; then
    echo ""
    echo "No controller"
    exit 0
fi

INFO=$(upower -i "$DEVICE")
BAT=$(echo "$INFO" | awk '/percentage/ {print $2}')
NAME=$(echo "$INFO" | awk -F': *' '/model/ {print $2}')

echo "󰊴 $BAT"
echo "$NAME"
