#!/bin/bash

STATUS=$(warp-cli status 2>/dev/null | grep -oP '(?<=Status update: )\S+')

# Return the current WARP egress IP. In proxy mode the trace request has to go
# through the local WARP proxy; in full-tunnel mode a plain request already
# leaves through WARP.
warp_ip() {
    local port ip

    port=$(warp-cli settings 2>/dev/null |
        sed -n 's/.*WarpProxy on port \([0-9][0-9]*\).*/\1/p' |
        head -n 1)

    for _ in $(seq 1 20); do
        if [ "$(warp-cli status 2>/dev/null | grep -oP '(?<=Status update: )\S+')" = "Connected" ]; then
            if [ -n "$port" ]; then
                ip=$(curl -s --max-time 4 -x "http://127.0.0.1:$port" \
                    https://www.cloudflare.com/cdn-cgi/trace |
                    sed -n 's/^ip=//p' | head -n 1)
            else
                ip=$(curl -s --max-time 4 \
                    https://www.cloudflare.com/cdn-cgi/trace |
                    sed -n 's/^ip=//p' | head -n 1)
            fi

            if [ -n "$ip" ]; then
                printf '%s' "$ip"
                return
            fi
        fi
        sleep 0.5
    done
}

if [ "$STATUS" = "Connected" ]; then
    warp-cli disconnect >/dev/null
    dunstify "WARP Disconnected" "Cloudflare WARP is now off" -i network-offline -t 3000
else
    warp-cli connect >/dev/null
    IP=$(warp_ip)
    if [ -n "$IP" ]; then
        dunstify "WARP Connected" "Cloudflare WARP is now on (IP: $IP)" -i network-vpn -t 3000
    else
        dunstify "WARP Connected" "Cloudflare WARP is now on" -i network-vpn -t 3000
    fi
fi
