#!/bin/bash
set -uo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*"; }

# Track failed steps instead of aborting the whole script on the first error
FAILURES=()
run() {
    local desc="$1"; shift
    if "$@"; then
        return 0
    fi
    error "Failed: $desc"
    FAILURES+=("$desc")
    return 1
}

info "Installing scripts to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
if [[ -f "$DOTFILES_DIR/_setup/bin/changelogs" ]]; then
    if run "copy changelogs script" cp "$DOTFILES_DIR/_setup/bin/changelogs" "$HOME/.local/bin/changelogs"; then
        run "make changelogs executable" chmod +x "$HOME/.local/bin/changelogs"
    fi
else
    warn "_setup/bin/changelogs not found, skipping"
fi

info "Moving wallpaper to Pictures..."
WALLPAPER="$HOME/Pictures/default.jpg"

# Generate theme from wallpaper
info "Generating theme from wallpaper..."
if [[ -f "$WALLPAPER" ]]; then
    run "generate theme from wallpaper" matugen image "$WALLPAPER" -t scheme-fruit-salad --source-color-index 0
else
    warn "wallpaper not found at $WALLPAPER, skipping theme generation"
fi

# Tailscale login and configuration
if command -v tailscale &>/dev/null; then
    info "Logging in to Tailscale..."
    run "tailscale login" sudo tailscale login

    info "Configuring Tailscale..."
    run "set tailscale operator" sudo tailscale set --operator="$USER"
    run "configure tailscale systray" tailscale configure systray --enable-startup=freedesktop
fi

# Cloudflare WARP setup
if command -v warp-cli &>/dev/null; then
    info "Setting up Cloudflare WARP..."
    run "symlink resolv.conf" sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    run "enable warp-svc" sudo systemctl enable --now warp-svc
    run "register WARP" warp-cli registration new
fi

# Disable copy-on-write for Steam library (avoids btrfs fragmentation)
STEAMAPPS="$HOME/.local/share/Steam/steamapps"

if [[ "$(findmnt -no FSTYPE -T "$HOME" 2>/dev/null)" != "btrfs" ]]; then
    info "Not btrfs, skipping CoW setup"
elif [[ -d "$STEAMAPPS/common" ]] && [[ -n "$(ls -A "$STEAMAPPS/common" 2>/dev/null)" ]]; then
    warn "steamapps already populated — +C won't apply retroactively, needs manual migration"
else
    info "Disabling CoW for Steam library..."
    mkdir -p "$STEAMAPPS"
    run "disable CoW on steamapps" chattr +C "$STEAMAPPS"

    # keep proton prefixes and saves CoW so they retain checksums
    mkdir -p "$STEAMAPPS/compatdata"
    run "keep CoW on compatdata" chattr -C "$STEAMAPPS/compatdata"
fi

# Cleanup dotfiles directory
info "Cleaning up dotfiles directory..."
if [[ -n "$DOTFILES_DIR" && -d "$DOTFILES_DIR" ]]; then
    run "remove dotfiles directory" rm -rf "$DOTFILES_DIR"
else
    warn "DOTFILES_DIR not set or missing, skipping cleanup"
fi

# Summary
echo
if ((${#FAILURES[@]} > 0)); then
    warn "${BOLD}Completed with ${#FAILURES[@]} failed step(s):${NC}"
    for f in "${FAILURES[@]}"; do
        echo -e "  ${RED}-${NC} $f"
    done
    echo
fi
echo -e "${BOLD}Post install cleanup completed.${NC}"
