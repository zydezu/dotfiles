#!/bin/bash
# Wrapper around ddcutil that retries on failure (I2C is flaky).
# Usage: brightness.sh <value> [display]
#   value:   brightness 0-100
#   display: 1 or 2 or "all" (default: all)

VALUE="$1"
TARGET="${2:-all}"
RETRIES=5
DELAY=0.5

if [[ -z "$VALUE" || ! "$VALUE" =~ ^[0-9]+$ || "$VALUE" -gt 100 ]]; then
    echo "Usage: $0 <value 0-100> [1|2|all]" >&2
    exit 1
fi

ddc_set() {
    local display="$1"
    local attempt
    for attempt in $(seq 1 "$RETRIES"); do
        if ddcutil --sleep-multiplier 0.1 setvcp 10 "$VALUE" --display "$display" &>/dev/null; then
            return 0
        fi
        sleep "$DELAY"
    done
    echo "brightness.sh: failed to set display $display after $RETRIES attempts" >&2
    return 1
}

case "$TARGET" in
    1) ddc_set 1 ;;
    2) ddc_set 2 ;;
    all)
        ddc_set 1
        ddc_set 2
        ;;
    *)
        echo "Usage: $0 <value> [1|2|all]" >&2
        exit 1
        ;;
esac
