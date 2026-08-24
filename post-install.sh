#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }

info "Moving wallpaper to Pictures..."
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
fi

# Cloudflare WARP setup
if command -v warp-cli &>/dev/null; then
    info "Setting up Cloudflare WARP..."
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    sudo systemctl enable --now warp-svc
    warp-cli registration new
fi

# Disable copy-on-write for Steam library (avoids btrfs fragmentation)
STEAMAPPS="$HOME/.local/share/Steam/steamapps"

if [[ "$(findmnt -no FSTYPE -T "$HOME")" != "btrfs" ]]; then
    info "Not btrfs, skipping CoW setup"
elif [[ -d "$STEAMAPPS/common" ]] && [[ -n "$(ls -A "$STEAMAPPS/common" 2>/dev/null)" ]]; then
    warn "steamapps already populated — +C won't apply retroactively, needs manual migration"
else
    info "Disabling CoW for Steam library..."
    mkdir -p "$STEAMAPPS"
    chattr +C "$STEAMAPPS"

    # keep proton prefixes and saves CoW so they retain checksums
    mkdir -p "$STEAMAPPS/compatdata"
    chattr -C "$STEAMAPPS/compatdata"
fi

# Cleanup dotfiles directory
info "Cleaning up dotfiles directory..."
rm -rf "$DOTFILES_DIR"

echo
echo -e "${BOLD}Post install cleanup completed.${NC}"
