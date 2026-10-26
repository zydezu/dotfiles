#!/bin/bash
# VRAM usage meter for waybar (NVIDIA)

out=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
if [ -z "$out" ]; then
    printf '{"text":"N/A","tooltip":"No GPU detected"}'
    exit 0
fi

used=$(echo "$out" | awk -F, '{gsub(/ /,"",$1); print $1}')
total=$(echo "$out" | awk -F, '{gsub(/ /,"",$2); print $2}')

if [ -z "$used" ] || [ -z "$total" ] || [ "$total" = "0" ]; then
    printf '{"text":"N/A","tooltip":"GPU query failed"}'
    exit 0
fi

used_g=$(awk "BEGIN{printf \"%.1f\", $used/1024}")
total_g=$(awk "BEGIN{printf \"%.1f\", $total/1024}")
pct=$(awk "BEGIN{printf \"%.0f\", $used/$total*100}")

printf '{"text":"%sG","tooltip":"VRAM: %s / %s MiB (%s%%)"}' "$used_g" "$used" "$total" "$pct"
