#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }

info "Moving wallpaper to Pictures..."
mkdir -p "$HOME/Pictures"
cp "$DOTFILES_DIR/waypaper/default.jpg" "$HOME/Pictures/default.jpg"
WALLPAPER="$HOME/Pictures/default.jpg"

# Generate theme from wallpaper
info "Generating theme from wallpaper..."
matugen image "$WALLPAPER" -t scheme-fruit-salad --source-color-index 0

# Tailscale login and configuration
if command -v tailscale &>/dev/null; then
    info "Logging in to Tailscale..."
    sudo tailscale login

    info "Configuring Tailscale..."
    sudo tailscale set --operator="$USER"
    tailscale configure systray --enable-startup=freedesktop

    info "Mounting Tailscale WebDAV share..."
    sudo mount -t davfs http://100.100.100.100:8080 /mnt/tailscale
    xdg-open /mnt/tailscale
fi

# Cleanup dotfiles directory
info "Cleaning up dotfiles directory..."
rm -rf "$DOTFILES_DIR"

echo
echo -e "${BOLD}Clean up completed.${NC}"
