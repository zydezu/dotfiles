#!/bin/bash
# VRAM usage meter for waybar (NVIDIA)

out=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
if [ -z "$out" ]; then
    printf '{"text":"N/A","tooltip":"No GPU detected"}'
    exit 0
fi

# One awk pass instead of five: parse the two fields and compute all values.
read -r used total used_g total_g pct < <(
    awk -F, '{
        gsub(/ /, "", $1); gsub(/ /, "", $2)
        if ($2 + 0 == 0) { printf "%s %s 0 0 0\n", $1, $2; next }
        printf "%s %s %.1f %.1f %.0f\n", $1, $2, $1/1024, $2/1024, $1/$2*100
    }' <<<"$out"
)

if [ -z "$used" ] || [ -z "$total" ] || [ "$total" = "0" ]; then
    printf '{"text":"N/A","tooltip":"GPU query failed"}'
    exit 0
fi

printf '{"text":"%sG","tooltip":"VRAM: %s / %s MiB (%s%%)"}' "$used_g" "$used" "$total" "$pct"
