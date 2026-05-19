#!/bin/bash
grim -g "$(slurp -p)" -t ppm - | magick - -format '%[pixel:u]' info:- | \
  sed 's/srgb(\([0-9]*\),\([0-9]*\),\([0-9]*\))/\1 \2 \3/' | \
  awk '{printf "#%02X%02X%02X", $1, $2, $3}' | \
  tee >(wl-copy) | \
  dunstify "Colour hex value copied to clipboard" "$(cat)" -t 2000
