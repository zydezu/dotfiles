#!/bin/bash
set -uo pipefail

if [[ "$EUID" -eq 0 ]]; then
    echo "Do not run this script as root. Run it as your normal user; sudo is called internally."
    exit 1
fi

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
if [[ -z "$DOTFILES_DIR" ]]; then
    echo "Could not resolve dotfiles directory" >&2
    exit 1
fi
CONFIG_DIR="$HOME/.config"

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

# Keep sudo alive for the duration of the script
if ! sudo -v; then
    error "sudo authentication failed"
    exit 1
fi
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &

# Install yay
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    run "install yay" sudo pacman -S --needed --noconfirm git go base-devel yay
fi

WALLPAPER="$DOTFILES_DIR/waypaper/default.jpg"

# Install packages
info "Installing packages..."
run "install packages" yay -S --needed --noconfirm \
    mangowm waybar-git matugen sddm \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-terminal-exec-git \
    xfce-polkit hyprlock hypridle swaync sway-audio-idle-inhibit-git \
    rofi rofi-power-menu \
    swaybg waypaper grim slurp wayfreeze-git swappy gpu-screen-recorder \
    clipse wl-clipboard wl-clip-persist \
    networkmanager dunst brightnessctl \
    pipewire wireplumber wiremix \
    alacritty fish zed helium-browser-bin \
    nautilus actions-for-nautilus-git baazar gnome-keyring gnome-font-viewer baobab file-roller fuse2 p7zip unzip \
    mpv qimgv libheif libavif qt5-avif-image-plugin qt6-avif-image-plugin qt5-jpegxl-image-plugin qt6-jpegxl-image-plugin qt-heif-image-plugin qtraw  \
    fastfetch bluetui wlctl github-cli uv \
    adw-gtk-theme ttf-jetbrains-mono-nerd noto-fonts adwaita-fonts \
    qt5ct qt6ct qt6-declarative qt6-svg qt5-quickcontrols qt5-quickcontrols2 qt5-declarative qt5-graphicaleffects

# Set fish as default shell
info "Setting fish as default shell..."
if command -v fish &>/dev/null; then
    run "set fish as default shell" chsh -s "$(command -v fish)"
else
    warn "fish not found, skipping default shell change"
fi

# Copy dotfiles
info "Copying dotfiles to $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
dirs=(
    actions-for-nautilus alacritty bluetui clipse environment.d fastfetch fish
    hypr mango matugen rofi swappy swaync
    qt5ct qt6ct waypaper wiremix wlctl xdg-desktop-portal zed
)
for dir in "${dirs[@]}"; do
    src="$DOTFILES_DIR/$dir"
    if [[ -d "$src" ]]; then
        rm -rf "$CONFIG_DIR/$dir"
        if cp -r "$src" "$CONFIG_DIR/"; then
            info "  $dir"
        else
            error "  failed to copy $dir"
            FAILURES+=("copy $dir to $CONFIG_DIR")
        fi
    else
        warn "  skipping $dir (not found)"
    fi
done

if [[ -f "$DOTFILES_DIR/xdg-terminals.list" ]]; then
    run "copy xdg-terminals.list" cp "$DOTFILES_DIR/xdg-terminals.list" "$CONFIG_DIR/xdg-terminals.list"
else
    warn "xdg-terminals.list not found, skipping"
fi

# Fix hardcoded /home/zy/ references left in copied configs
run "fix hardcoded home paths" find "$CONFIG_DIR" -type f \( -name "*.conf" -o -name "*.ini" -o -name "*.json" -o -name "*.jsonc" \) \
    -exec sed -i "s|/home/zy/|$HOME/|g" {} +

# Guard optional dev-tool sourcing in fish config (tool may not be installed on this machine)
info "Guarding optional tool sourcing in fish config..."
if [[ -f "$CONFIG_DIR/fish/config.fish" ]]; then
    run "guard fnm sourcing" sed -i \
        's/^fnm env --use-on-cd --shell fish | source$/if type -q fnm\n    fnm env --use-on-cd --shell fish | source\nend/' \
        "$CONFIG_DIR/fish/config.fish"
else
    warn "fish/config.fish not found, skipping fnm guard"
fi
if [[ -f "$CONFIG_DIR/fish/conf.d/deno.fish" ]]; then
    run "guard deno.fish sourcing" sed -i \
        's|^source "/home/zy/\.deno/env\.fish"$|test -f "$HOME/.deno/env.fish"; and source "$HOME/.deno/env.fish"|' \
        "$CONFIG_DIR/fish/conf.d/deno.fish"
else
    warn "fish/conf.d/deno.fish not found, skipping deno guard"
fi
if [[ -f "$CONFIG_DIR/fish/conf.d/rustup.fish" ]]; then
    run "guard rustup.fish sourcing" sed -i \
        's|^source "$HOME/\.cargo/env\.fish"$|test -f "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"|' \
        "$CONFIG_DIR/fish/conf.d/rustup.fish"
else
    warn "fish/conf.d/rustup.fish not found, skipping rustup guard"
fi
if [[ -f "$CONFIG_DIR/fish/conf.d/uv.env.fish" ]]; then
    run "guard uv.env.fish sourcing" sed -i \
        's|^source "$HOME/\.local/bin/env\.fish"$|test -f "$HOME/.local/bin/env.fish"; and source "$HOME/.local/bin/env.fish"|' \
        "$CONFIG_DIR/fish/conf.d/uv.env.fish"
else
    warn "fish/conf.d/uv.env.fish not found, skipping uv guard"
fi

# Configure actions-for-nautilus
info "Configuring actions-for-nautilus..."
mkdir -p "$HOME/.local/share/actions-for-nautilus"
if [[ -f "$CONFIG_DIR/actions-for-nautilus/config.json" ]]; then
    run "copy actions-for-nautilus config" cp "$CONFIG_DIR/actions-for-nautilus/config.json" \
       "$HOME/.local/share/actions-for-nautilus/config.json"
else
    warn "actions-for-nautilus config.json not found, skipping"
fi
nautilus -q 2>/dev/null || true

# Nautilus bookmarks
info "Adding Nautilus bookmarks..."
mkdir -p "$HOME/.config/gtk-3.0"
if ! cat > "$HOME/.config/gtk-3.0/bookmarks" <<EOF
file://$HOME/Documents Documents
file://$HOME/Downloads Downloads
file://$HOME/Projects Projects
file://$HOME/Music Music
file://$HOME/Pictures Pictures
file://$HOME/Videos Videos
EOF
then
    error "Failed to write Nautilus bookmarks"
    FAILURES+=("write Nautilus bookmarks")
fi

# Laptop-specific config
if ls /sys/class/power_supply/BAT* &>/dev/null; then
    info "Laptop detected - applying laptop config..."
    if [[ -f "$CONFIG_DIR/mango/waybar/config.laptop.jsonc" ]]; then
        run "apply laptop waybar config" cp "$CONFIG_DIR/mango/waybar/config.laptop.jsonc" "$CONFIG_DIR/mango/waybar/config.jsonc"
    else
        warn "laptop waybar config not found, skipping"
    fi
    if [[ -f "$CONFIG_DIR/mango/config.conf" ]]; then
        run "set sloppyfocus" sed -i 's/^sloppyfocus=.*/sloppyfocus=1/' "$CONFIG_DIR/mango/config.conf"
    else
        warn "mango/config.conf not found, skipping sloppyfocus"
    fi
fi

# Strip monitor-specific config lines
info "Stripping monitor config..."

if [[ -f "$CONFIG_DIR/mango/monitor.conf" ]]; then
    run "strip monitorrule lines" sed -i '/^monitorrule=/d' "$CONFIG_DIR/mango/monitor.conf"
else
    warn "mango/monitor.conf not found, skipping"
fi

if [[ -f "$CONFIG_DIR/mango/waybar/config.jsonc" ]]; then
    run "strip waybar output line" sed -i '/"output":/d' "$CONFIG_DIR/mango/waybar/config.jsonc"
else
    warn "mango/waybar/config.jsonc not found, skipping"
fi

if [[ -f "$CONFIG_DIR/swaync/config.json" ]]; then
    run "strip swaync preferred-output lines" sed -i \
        -e '/"control-center-preferred-output":/d' \
        -e '/"notification-window-preferred-output":/d' \
        "$CONFIG_DIR/swaync/config.json"
else
    warn "swaync/config.json not found, skipping"
fi

# Strip scripts
if [[ -f "$CONFIG_DIR/mango/scripts/fullscreendnd.sh" ]]; then
    run "strip hardcoded monitor" sed -i '/^MAIN_MON=/d' "$CONFIG_DIR/mango/scripts/fullscreendnd.sh"
else
    warn "mango/scripts/fullscreendnd.sh not found, skipping"
fi

if [[ -f "$CONFIG_DIR/mango/binds.conf" ]]; then
    run "strip capture/kiosk binds" sed -i '/^# Capture\/Kiosk$/,/^$/d' "$CONFIG_DIR/mango/binds.conf"
else
    warn "mango/binds.conf not found, skipping"
fi

# Remove machine-specific kiosk/capture-card scripts
machine_scripts=(
    statuskiosk.sh tplinkstatskiosk.sh watchkiosk.sh
    findcog.sh movecogwin.sh minimizeapps.sh
    capturecardsetup.sh webview-css-inject.py
)
for script in "${machine_scripts[@]}"; do
    if [[ -f "$CONFIG_DIR/mango/scripts/$script" ]]; then
        run "remove mango/scripts/$script" rm -f "$CONFIG_DIR/mango/scripts/$script"
    fi
done

if [[ -f "$CONFIG_DIR/mango/autostart.sh" ]]; then
    run "strip minimizeapps autostart" sed -i \
        -e '/^# Minimize some apps on startup$/d' \
        -e '/minimizeapps\.sh/d' \
        "$CONFIG_DIR/mango/autostart.sh"
else
    warn "mango/autostart.sh not found, skipping"
fi

# hypr/hyprlock.conf - remove monitor-only background blocks, then strip monitor= lines
if [[ -f "$CONFIG_DIR/hypr/hyprlock.conf" ]]; then
    run "strip monitor-only blocks from hyprlock.conf" python3 -c "
import re
f = '$CONFIG_DIR/hypr/hyprlock.conf'
t = open(f).read()
t = re.sub(r'\nbackground \{[^}]*\}', lambda m: '' if 'path =' not in m.group() else m.group(), t)
t = re.sub(r'[ \t]*monitor = [^\n]*\n', '', t)
open(f, 'w').write(t)
"
else
    warn "hypr/hyprlock.conf not found, skipping"
fi

# Wallpaper + matugen
info "Moving wallpaper to Pictures..."
mkdir -p "$HOME/Pictures"
if [[ -f "$WALLPAPER" ]]; then
    run "copy wallpaper" cp "$WALLPAPER" "$HOME/Pictures/default.jpg"
    WALLPAPER="$HOME/Pictures/default.jpg"
else
    warn "wallpaper source not found at $WALLPAPER, skipping"
fi

info "Setting wallpaper in waypaper config..."
if [[ -f "$CONFIG_DIR/waypaper/config.ini" ]]; then
    run "set waypaper wallpaper" sed -i "s|^wallpaper = .*|wallpaper = $WALLPAPER|" "$CONFIG_DIR/waypaper/config.ini"
else
    warn "waypaper/config.ini not found, skipping"
fi

info "Generating theme from wallpaper..."
# matugen image "$WALLPAPER" -t scheme-fruit-salad --source-color-index 0 2>/dev/null || true

# mpv config
info "Cloning mpv config..."
rm -rf "$CONFIG_DIR/mpv"
run "clone mpv config" git clone --depth 1 https://github.com/zydezu/mpvconfig.git "$CONFIG_DIR/mpv"

# Neuwaita icon theme
info "Installing Neuwaita icon theme..."
ICONS_DIR="$HOME/.local/share/icons/Neuwaita"
rm -rf "$ICONS_DIR"
mkdir -p "$HOME/.local/share/icons"
if [[ -f "$DOTFILES_DIR/_setup/icons/Neuwaita.zip" ]]; then
    run "extract Neuwaita icon theme" unzip -qo "$DOTFILES_DIR/_setup/icons/Neuwaita.zip" -d "$HOME/.local/share/icons"
else
    warn "Neuwaita.zip not found, skipping icon theme install"
fi

# GTK dark mode
info "Setting GTK dark mode..."
run "set color-scheme" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
run "set gtk-theme" gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
run "set icon-theme" gsettings set org.gnome.desktop.interface icon-theme 'Neuwaita'

# Enable systemd services
info "Enabling system services..."
run "enable NetworkManager/bluetooth" sudo systemctl enable NetworkManager bluetooth

info "Enabling user audio services..."
run "enable pipewire/wireplumber" systemctl --user enable pipewire pipewire-pulse wireplumber

# XDG user directories
info "Creating XDG user directories..."
run "run xdg-user-dirs-update" xdg-user-dirs-update

# Templates
info "Copying templates..."
if [[ -d "$DOTFILES_DIR/_setup/Templates" ]]; then
    mkdir -p "$HOME/Templates"
    run "copy templates" cp -r "$DOTFILES_DIR/_setup/Templates/." "$HOME/Templates/"
else
    warn "_setup/Templates not found, skipping"
fi

# Extension configs (uBlock, SponsorBlock, Tampermonkey)
info "Copying extension configs to Downloads..."
if [[ -d "$DOTFILES_DIR/_setup/extensionconfigs" ]]; then
    mkdir -p "$HOME/Downloads"
    run "copy extension configs" cp -r "$DOTFILES_DIR/_setup/extensionconfigs/." "$HOME/Downloads/"
else
    warn "_setup/extensionconfigs not found, skipping"
fi

# AppManager
info "Installing AppManager..."
mkdir -p "$HOME/Applications"
appmanager_url=$(curl -fsSL https://api.github.com/repos/kem-a/AppManager/releases/latest \
    | grep browser_download_url \
    | grep "x86_64.AppImage\"" \
    | head -1 \
    | sed 's/.*"\(https[^"]*\)".*/\1/')
if [[ -z "$appmanager_url" ]]; then
    error "Could not determine AppManager download URL"
    FAILURES+=("resolve AppManager download URL")
elif run "download AppManager" curl -fL "$appmanager_url" -o "$HOME/Applications/AppManager.AppImage"; then
    run "make AppManager executable" chmod +x "$HOME/Applications/AppManager.AppImage"
fi

# SDDM themes
info "Installing SDDM themes..."
sudo mkdir -p /usr/share/sddm/themes
if [[ -d "$DOTFILES_DIR/_setup/sddmthemes" ]]; then
    run "install SDDM themes" sudo cp -r "$DOTFILES_DIR/_setup/sddmthemes/." /usr/share/sddm/themes/
else
    warn "_setup/sddmthemes not found, skipping"
fi
sudo rm -f /etc/sddm.conf.d/theme.conf
if [[ -f /etc/sddm.conf.d/kde_settings.conf ]]; then
    run "set SDDM theme" sudo sed -i 's/^Current=.*/Current=glyph/' /etc/sddm.conf.d/kde_settings.conf
else
    sudo mkdir -p /etc/sddm.conf.d
    if ! sudo tee /etc/sddm.conf.d/kde_settings.conf > /dev/null <<'EOF'
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=glyph

[Users]
MaximumUid=60513
MinimumUid=1000
EOF
    then
        error "Failed to write SDDM kde_settings.conf"
        FAILURES+=("write SDDM kde_settings.conf")
    fi
fi

# /etc/environment
info "Writing /etc/environment..."
if [[ -f "$DOTFILES_DIR/_setup/environment" ]]; then
    if run "write /etc/environment" sudo cp "$DOTFILES_DIR/_setup/environment" /etc/environment; then
        if ! lspci | grep -qi nvidia; then
            run "strip NVIDIA env var" sudo sed -i '/__NV_DISABLE_EXPLICIT_SYNC/d' /etc/environment
        fi
    fi
else
    warn "_setup/environment not found, skipping"
fi

# Steam + gamescope
read -rp "Install Steam and gamescope? [y/N] " _steam
if [[ "$_steam" =~ ^[Yy]$ ]]; then
    info "Installing Steam and gamescope..."
    run "install Steam/gamescope" yay -S --needed --noconfirm steam gamescope
fi

# Discord
read -rp "Install Discord? [y/N] " _discord
if [[ "$_discord" =~ ^[Yy]$ ]]; then
    info "Installing Discord..."
    run "install Discord" yay -S --needed --noconfirm discord
fi

# Warp
read -rp "Install Cloudflare Warp? [y/N] " _warp
if [[ "$_warp" =~ ^[Yy]$ ]]; then
    info "Installing Warp..."
    run "install Cloudflare Warp" yay -S --needed --noconfirm warp-cli
fi

if ! command -v warp-cli &>/dev/null; then
    info "Cloudflare Warp not installed - removing warptoggle bind..."
    if [[ -f "$CONFIG_DIR/mango/scripts/warptoggle.sh" ]]; then
        run "remove mango/scripts/warptoggle.sh" rm -f "$CONFIG_DIR/mango/scripts/warptoggle.sh"
    fi
    if [[ -f "$CONFIG_DIR/mango/binds.conf" ]]; then
        run "strip warptoggle bind" sed -i '/warptoggle\.sh/d' "$CONFIG_DIR/mango/binds.conf"
    fi
fi

# yt-dlp
read -rp "Install yt-dlp and gallery-dl? [y/N] " _ytdlp
if [[ "$_ytdlp" =~ ^[Yy]$ ]]; then
    info "Installing yt-dlp..."
    run "install yt-dlp/gallery-dl" yay -S --needed --noconfirm yt-dlp yt-dlp-ejs deno gallery-dl
fi

# Tailscale
read -rp "Install Tailscale? [y/N] " _ts
if [[ "$_ts" =~ ^[Yy]$ ]]; then
    info "Installing Tailscale..."
    if run "install Tailscale" yay -S --needed --noconfirm tailscale davfs2; then
        run "enable tailscaled" sudo systemctl enable --now tailscaled
        run "set tailscale operator" sudo tailscale set --operator="$USER"
    fi
fi

# Enable SDDM
info "Enabling SDDM..."
run "enable SDDM" sudo systemctl enable sddm

# Remove Plymouth boot animation
info "Removing Plymouth boot animation..."
sudo pacman -Rns --noconfirm plymouth cachyos-plymouth-bootanimation cachyos-plymouth-theme 2>/dev/null || true
if [[ -f /etc/mkinitcpio.conf ]]; then
    if run "strip plymouth hook" sudo sed -i '/^HOOKS=/s/\bplymouth\b[[:space:]]*//' /etc/mkinitcpio.conf; then
        run "rebuild initramfs" sudo mkinitcpio -P
    fi
else
    warn "/etc/mkinitcpio.conf not found, skipping Plymouth hook removal"
fi

# Install fonts
info "Installing fonts..."
mkdir -p "$HOME/.local/share/fonts"
if compgen -G "$DOTFILES_DIR/_setup/fonts.part*.7z" > /dev/null; then
    cat "$DOTFILES_DIR"/_setup/fonts.part*.7z > /tmp/fonts.7z
    run "extract fonts" 7z x -y -o"$HOME/.local/share" /tmp/fonts.7z
    rm -f /tmp/fonts.7z
else
    warn "fonts archive parts not found, skipping font install"
fi

# Rebuild font cache
info "Rebuilding font cache..."
run "rebuild font cache" fc-cache -fv

# Copy post-install script to home
info "Copying post-install script..."
if [[ -f "$DOTFILES_DIR/post-install.sh" ]]; then
    if run "copy post-install.sh" cp "$DOTFILES_DIR/post-install.sh" "$HOME/post-install.sh"; then
        run "set DOTFILES_DIR in post-install.sh" sed -i "s|DOTFILES_DIR=.*|DOTFILES_DIR=\"$DOTFILES_DIR\"|" "$HOME/post-install.sh"
        run "make post-install.sh executable" chmod +x "$HOME/post-install.sh"
    fi
else
    error "post-install.sh not found in dotfiles dir"
    FAILURES+=("copy post-install.sh")
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

# Reboot
echo -e "${YELLOW}[!]${NC} ${BOLD}Run ~/post-install.sh after logging in to generate the theme and finish setup.${NC}"
echo
echo -e "${BOLD}Done. Rebooting in 5 seconds... (Ctrl+C to cancel)${NC}"
sleep 5
reboot
