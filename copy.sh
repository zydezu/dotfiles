#!/bin/bash

CONFIG_DIR="$HOME/.config"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DEST="$SCRIPT_DIR"

allowed_dirs=(
  actions-for-nautilus
  alacritty
  clipse
  environment.d
  fastfetch
  fish
  gpu-screen-recorder
  hypr
  impala
  mango
  matugen
  mprisence
  mpv
  rofi
  swappy
  swaync
  waypaper
  xdg-desktop-portal
  zed
)

for dir in "${allowed_dirs[@]}"; do
    SRC="$CONFIG_DIR/$dir"

    if [[ -d "$SRC" ]]; then
        echo "Updating $dir..."

        rm -rf "$DEST/$dir"
        cp -r "$SRC" "$DEST/"
    else
        echo "Skipping $dir (not found in ~/.config)"
    fi
done
