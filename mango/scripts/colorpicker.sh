#!/usr/bin/env bash
PICK="$(slurp -p -f '%o %X %Y %x %y')" || exit 1
read -r o x y gx gy <<<"$PICK"
F='#%[hex:p{0,0}]\n'
HEX=$(grim -o "$o" -s 1 -t ppm - 2>/dev/null | magick - -crop "1x1+$x+$y" +repage -depth 8 -format "$F" info:- 2>/dev/null)
[ -z "$HEX" ] && HEX=$(grim -g "$gx,$gy 1x1" -t ppm - 2>/dev/null | magick - -depth 8 -format "$F" info:- 2>/dev/null)
[ -z "$HEX" ] && exit 1
printf '%s' "$HEX" | tee /tmp/hex_color.txt | wl-copy
magick -size 32x32 -depth 8 "xc:$HEX" /tmp/color_swatch.png
dunstify "Hex value copied to clipboard:" "$HEX" -i /tmp/color_swatch.png -t 4000
