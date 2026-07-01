#!/bin/bash

CONFIG_DIR="$HOME/.config"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DEST="$SCRIPT_DIR"

allowed_dirs=(
  actions-for-nautilus
  alacritty
  bluetui
  clipse
  environment.d
  fastfetch
  fish
  gtk-3.0
  gtk-4.0
  hypr
  mango
  matugen
  mpv
  rofi
  swappy
  swaync
  qt5ct
  qt6ct
  waypaper
  wiremix
  wlctl
  xdg-desktop-portal
  zed
)

protected_dirs=(_setup)

for dir in "${allowed_dirs[@]}"; do
    SRC="$CONFIG_DIR/$dir"

    for protected in "${protected_dirs[@]}"; do
        if [[ "$dir" == "$protected" ]]; then
            echo "Skipping $dir (protected)"
            continue 2
        fi
    done

    if [[ -d "$SRC" ]]; then
        echo "Updating $dir..."

        rm -rf "$DEST/$dir"
        cp -r "$SRC" "$DEST/"
    else
        echo "Skipping $dir (not found in ~/.config)"
    fi
done
