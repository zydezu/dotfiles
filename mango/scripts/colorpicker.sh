#!/bin/bash
GEOMETRY="$(slurp -p)"
grim -g "$GEOMETRY" -t ppm - | magick - -format '%[pixel:u]' info:- | \
  sed 's/srgb(\([0-9]*\),\([0-9]*\),\([0-9]*\))/\1 \2 \3/' | \
  awk '{printf "#%02X%02X%02X", $1, $2, $3}' | \
  tee >(wl-copy) > /tmp/hex_color.txt
HEX=$(cat /tmp/hex_color.txt)
magick -size 32x32 xc:"$HEX" /tmp/color_swatch.png
dunstify "Hex value copied to clipboard:" "$HEX" -i /tmp/color_swatch.png -t 2000
