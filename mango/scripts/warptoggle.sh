#!/bin/bash

STATUS=$(warp-cli status 2>/dev/null | grep -oP '(?<=Status update: )\S+')

if [ "$STATUS" = "Connected" ]; then
    warp-cli disconnect >/dev/null
    dunstify "WARP Disconnected" "Cloudflare WARP is now off" -i network-offline -t 3000
else
    warp-cli connect >/dev/null
    dunstify "WARP Connected" "Cloudflare WARP is now on" -i network-vpn -t 3000
fi
