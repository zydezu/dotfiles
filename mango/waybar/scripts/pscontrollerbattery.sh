#!/bin/bash

DEVICE=$(upower -e | grep -m1 'battery_ps_controller')

if [ -z "$DEVICE" ]; then
    echo ""
    echo "No controller"
    exit 0
fi

INFO=$(upower -i "$DEVICE")
read -r BAT NAME < <(awk -F': *' '/percentage/{b=$2} /model/{n=$2} END{print b, n}' <<<"$INFO")

echo "󰊴 $BAT"
echo "$NAME"
