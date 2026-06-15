#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }

WALLPAPER="$DOTFILES_DIR/waypaper/default.jpg"

# Generate theme from wallpaper
info "Generating theme from wallpaper..."
matugen image "$WALLPAPER" -t scheme-fruit-salad --source-color-index 0

# Tailscale login
if command -v tailscale &>/dev/null; then
    info "Logging in to Tailscale..."
    sudo tailscale login
fi

# Cleanup dotfiles directory
info "Cleaning up dotfiles directory..."
rm -rf "$DOTFILES_DIR"

info "Done."
