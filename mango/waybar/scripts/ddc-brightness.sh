#!/bin/bash
BUSES=(2 4)
STEP=5
STATE_FILE="/tmp/waybar_ddc_brightness"

get() {
  if [ ! -f "$STATE_FILE" ]; then
    val=$(ddcutil --bus "${BUSES[0]}" getvcp 10 | grep -oP 'current value =\s*\K[0-9]+')
    echo "$val" > "$STATE_FILE"
  fi
  cur=$(cat "$STATE_FILE")
  echo "{\"text\":\"${cur}%\",\"percentage\":${cur}}"
}

set_val() {
  cur=$(cat "$STATE_FILE" 2>/dev/null || echo 50)
  case "$1" in
    up) new=$((cur + STEP > 100 ? 100 : cur + STEP)) ;;
    down) new=$((cur - STEP < 0 ? 0 : cur - STEP)) ;;
    *) new=$1 ;;
  esac
  echo "$new" > "$STATE_FILE"
  for b in "${BUSES[@]}"; do
    pkill -f "ddcutil --bus $b setvcp 10" 2>/dev/null
    (ddcutil --bus "$b" setvcp 10 "$new" &>/dev/null &)
  done
  pkill -RTMIN+8 waybar
}

case "$1" in
  get) get ;;
  up|down) set_val "$1" ;;
  set) set_val "$2" ;;
esac
