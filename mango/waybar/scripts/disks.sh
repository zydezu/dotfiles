#!/bin/bash

disks=$(df -x tmpfs -x devtmpfs -x squashfs -x efivarfs -x overlay \
  --output=source,used,size,pcent \
  | awk 'NR>1 && /^\/dev\// && $3 > 2097152 && !seen[$1]++ {gsub(/%/,"",$4); printf "%s{\"dev\":\"%s\",\"used\":%s,\"total\":%s,\"pct\":%s}", \
    (count++>0?",":""), $1,$2,$3,$4}')

tooltip=$(echo "[${disks}]" | jq -r '.[] | "\(.dev)  \(.used / 1024 / 1024 | floor)G / \(.total / 1024 / 1024 | floor)G  (\(.pct)%)"' | paste -sd '\n')

main=$(echo "[${disks}]" | jq -r '[.[] | .pct] | max')

printf '{"text":"󰋊 %s%%","tooltip":"%s"}' "$main" "${tooltip//$'\n'/'\n'}"
