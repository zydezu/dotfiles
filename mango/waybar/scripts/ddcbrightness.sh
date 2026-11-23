#!/bin/bash
# DDC/CI brightness control for waybar.
#
# I2C bus numbers are not stable, they can change, so the buses are discovered at runtime

STEP=5
STATE_FILE="/tmp/waybar_ddcbrightness"
BUS_FILE="/tmp/waybar_ddcbrightness_buses"
CACHE_TTL=10 # seconds before a cached value is re-read from the hardware

# Print the I2C bus number of every detected DDC/CI display.
discover_buses() {
  ddcutil detect 2>/dev/null |
    grep -oP 'I2C bus:\s*/dev/i2c-\K[0-9]+'
}

# Print the cached bus list, detecting it first if the cache is missing.
get_buses() {
  local -a buses=()
  [ -s "$BUS_FILE" ] && read -ra buses <"$BUS_FILE"

  if [ ${#buses[@]} -eq 0 ]; then
    mapfile -t buses < <(discover_buses)
    [ ${#buses[@]} -eq 0 ] && return 1
    printf '%s ' "${buses[@]}" >"$BUS_FILE"
  fi

  printf '%s\n' "${buses[@]}"
}

# Print the brightness reported by the first display that answers.
read_brightness() {
  local attempt bus val
  for attempt in 1 2; do
    while read -r bus; do
      val=$(ddcutil --bus "$bus" getvcp 10 2>/dev/null |
        grep -oP 'current value =\s*\K[0-9]+')
      if [ -n "$val" ]; then
        printf '%s\n' "$val"
        return 0
      fi
    done < <(get_buses)

    # None of the cached buses answered: drop the cache and detect again.
    rm -f "$BUS_FILE"
  done
  return 1
}

# Print the current brightness, preferring the cache while it is fresh.
current_value() {
  local cur
  if [ -f "$STATE_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$STATE_FILE") )) -lt $CACHE_TTL ]; then
    cat "$STATE_FILE"
    return
  fi

  cur=$(read_brightness) || cur=$(cat "$STATE_FILE" 2>/dev/null) || cur=50
  printf '%s\n' "$cur" >"$STATE_FILE"
  printf '%s\n' "$cur"
}

get() {
  local cur
  cur=$(current_value)
  echo "{\"text\":\"${cur}%\",\"percentage\":${cur}}"
}

set_val() {
  local cur new bus
  cur=$(current_value)

  case "$1" in
    up) new=$((cur + STEP > 100 ? 100 : cur + STEP)) ;;
    down) new=$((cur - STEP < 0 ? 0 : cur - STEP)) ;;
    *) new=$1 ;;
  esac

  [[ "$new" =~ ^[0-9]+$ ]] || return 1
  ((new > 100)) && new=100

  printf '%s\n' "$new" >"$STATE_FILE"

  while read -r bus; do
    pkill -f "ddcutil --bus $bus setvcp 10" 2>/dev/null
    (ddcutil --bus "$bus" setvcp 10 "$new" &>/dev/null &)
  done < <(get_buses)

  pkill -RTMIN+8 waybar
}

case "$1" in
  get) get ;;
  up | down) set_val "$1" ;;
  set) set_val "$2" ;;
esac
