#!/bin/bash
set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
    echo "Do not run this script as root. Run it as your normal user; sudo is called internally."
    exit 1
fi

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONFIG_DIR="$HOME/.config"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# Keep sudo alive for the duration of the script
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &

# Install yay
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

WALLPAPER="$DOTFILES_DIR/waypaper/default.jpg"

# Install packages
info "Installing packages..."
yay -S --needed --noconfirm \
    mangowm waybar matugen sddm \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-terminal-exec-git \
    xfce-polkit hyprlock hypridle swaync sway-audio-idle-inhibit-git \
    rofi rofi-power-menu \
    swaybg waypaper grim slurp wayfreeze-git swappy gpu-screen-recorder \
    clipse cliphist wl-clipboard wl-clip-persist \
    networkmanager dunst brightnessctl \
    pipewire wireplumber wiremix \
    alacritty fish zed helium-browser-bin \
    nautilus actions-for-nautilus-git baazar baobab file-roller fuse2 \
    mpv qimgv \
    fastfetch bluetui wlctl github-cli uv \
    adw-gtk-theme ttf-jetbrains-mono-nerd noto-fonts adwaita-fonts \
    qt5ct qt6ct qt6-declarative qt6-svg qt5-quickcontrols qt5-quickcontrols2 qt5-declarative qt5-graphicaleffects

# Install uv
info "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Set fish as default shell
info "Setting fish as default shell..."
chsh -s /usr/bin/fish

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
        cp -r "$src" "$CONFIG_DIR/"
        info "  $dir"
    else
        warn "  skipping $dir (not found)"
    fi
done

cp "$DOTFILES_DIR/xdg-terminals.list" "$CONFIG_DIR/xdg-terminals.list"

# Fix hardcoded /home/zy/ references left in copied configs
find "$CONFIG_DIR" -type f \( -name "*.conf" -o -name "*.ini" -o -name "*.json" -o -name "*.jsonc" \) \
    -exec sed -i "s|/home/zy/|$HOME/|g" {} +

# Configure actions-for-nautilus
info "Configuring actions-for-nautilus..."
mkdir -p "$HOME/.local/share/actions-for-nautilus"
cp "$CONFIG_DIR/actions-for-nautilus/config.json" \
   "$HOME/.local/share/actions-for-nautilus/config.json"
nautilus -q 2>/dev/null || true

# Nautilus bookmarks
info "Adding Nautilus bookmarks..."
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/bookmarks" <<EOF
file://$HOME/Documents Documents
file://$HOME/Downloads Downloads
file://$HOME/Projects Projects
file://$HOME/Music Music
file://$HOME/Pictures Pictures
file://$HOME/Videos Videos
EOF

# Laptop-specific config
if ls /sys/class/power_supply/BAT* &>/dev/null; then
    info "Laptop detected - applying laptop config..."
    cp "$CONFIG_DIR/mango/waybar/config.laptop.jsonc" "$CONFIG_DIR/mango/waybar/config.jsonc"
    sed -i 's/^sloppyfocus=.*/sloppyfocus=1/' "$CONFIG_DIR/mango/config.conf"
fi

# Strip monitor-specific config lines
info "Stripping monitor config..."

# mango/monitor.conf - remove all monitorrule= lines
sed -i '/^monitorrule=/d' "$CONFIG_DIR/mango/monitor.conf"

# mango/waybar/config.jsonc - remove "output": "..." line
sed -i '/"output":/d' "$CONFIG_DIR/mango/waybar/config.jsonc"

# swaync/config.json - remove pfreferred-output lines
sed -i '/"control-center-preferred-output":/d'      "$CONFIG_DIR/swaync/config.json"
sed -i '/"notification-window-preferred-output":/d' "$CONFIG_DIR/swaync/config.json"

# mango/scripts/fullscreen-dnd.sh - remove hardcoded monitor
sed -i '/^MAIN_MON=/d' "$CONFIG_DIR/mango/scripts/fullscreen-dnd.sh"

# hypr/hyprlock.conf - remove monitor-only background blocks, then strip monitor= lines
python3 -c "
import re
f = '$CONFIG_DIR/hypr/hyprlock.conf'
t = open(f).read()
t = re.sub(r'\nbackground \{[^}]*\}', lambda m: '' if 'path =' not in m.group() else m.group(), t)
t = re.sub(r'[ \t]*monitor = [^\n]*\n', '', t)
open(f, 'w').write(t)
"

# Wallpaper + matugen
info "Moving wallpaper to Pictures..."
mkdir -p "$HOME/Pictures"
cp "$WALLPAPER" "$HOME/Pictures/default.jpg"
WALLPAPER="$HOME/Pictures/default.jpg"

info "Setting wallpaper in waypaper config..."
sed -i "s|^wallpaper = .*|wallpaper = $WALLPAPER|" "$CONFIG_DIR/waypaper/config.ini"

info "Generating theme from wallpaper..."
# matugen image "$WALLPAPER" -t scheme-fruit-salad --source-color-index 0 2>/dev/null || true

# mpv config
info "Cloning mpv config..."
rm -rf "$CONFIG_DIR/mpv"
git clone --depth 1 https://github.com/zydezu/mpvconfig.git "$CONFIG_DIR/mpv"

# Neuwaita icon theme
info "Installing Neuwaita icon theme..."
ICONS_DIR="$HOME/.local/share/icons/Neuwaita"
if [[ -d "$ICONS_DIR/.git" ]]; then
    git -C "$ICONS_DIR" pull
else
    git clone --depth 1 https://github.com/RusticBard/Neuwaita.git "$ICONS_DIR"
fi

# GTK dark mode
info "Setting GTK dark mode..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface icon-theme 'Neuwaita'

# Enable systemd services
info "Enabling system services..."
sudo systemctl enable NetworkManager bluetooth

info "Enabling user audio services..."
systemctl --user enable pipewire pipewire-pulse wireplumber

# XDG user directories
info "Creating XDG user directories..."
xdg-user-dirs-update

# Templates
info "Copying templates..."
cp -r "$DOTFILES_DIR/_setup/Templates/." "$HOME/Templates/"

# Extension configs (uBlock, SponsorBlock, Tampermonkey)
info "Copying extension configs to Downloads..."
cp -r "$DOTFILES_DIR/_setup/extensionconfigs/." "$HOME/Downloads/"

# AppManager
info "Installing AppManager..."
mkdir -p "$HOME/Applications"
appmanager_url=$(curl -s https://api.github.com/repos/kem-a/AppManager/releases/latest \
    | grep browser_download_url \
    | grep "x86_64.AppImage\"" \
    | head -1 \
    | sed 's/.*"\(https[^"]*\)".*/\1/')
curl -L "$appmanager_url" -o "$HOME/Applications/AppManager.AppImage"
chmod +x "$HOME/Applications/AppManager.AppImage"

# SDDM themes
info "Installing SDDM themes..."
sudo mkdir -p /usr/share/sddm/themes
sudo cp -r "$DOTFILES_DIR/_setup/sddmthemes/." /usr/share/sddm/themes/
sudo rm -f /etc/sddm.conf.d/theme.conf
if [[ -f /etc/sddm.conf.d/kde_settings.conf ]]; then
    sudo sed -i 's/^Current=.*/Current=glyph/' /etc/sddm.conf.d/kde_settings.conf
else
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/kde_settings.conf > /dev/null <<'EOF'
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
fi

# /etc/environment
info "Writing /etc/environment..."
sudo cp "$DOTFILES_DIR/_setup/environment" /etc/environment
if ! lspci | grep -qi nvidia; then
    sudo sed -i '/__NV_DISABLE_EXPLICIT_SYNC/d' /etc/environment
fi

# Steam + gamescope
read -rp "Install Steam and gamescope? [y/N] " _steam
if [[ "$_steam" =~ ^[Yy]$ ]]; then
    info "Installing Steam and gamescope..."
    yay -S --needed --noconfirm steam gamescope
fi

# Discord
read -rp "Install Discord? [y/N] " _discord
if [[ "$_discord" =~ ^[Yy]$ ]]; then
    info "Installing Discord..."
    yay -S --needed --noconfirm discord
fi

# Warp
read -rp "Install Cloudflare Warp? [y/N] " _warp
if [[ "$_warp" =~ ^[Yy]$ ]]; then
    info "Installing Warp..."
    yay -S --needed --noconfirm warp-cli
fi

# yt-dlp
read -rp "Install yt-dlp? [y/N] " _ytdlp
if [[ "$_ytdlp" =~ ^[Yy]$ ]]; then
    info "Installing yt-dlp..."
    yay -S --needed --noconfirm yt-dlp yt-dlp-ejs deno
fi

# Tailscale
read -rp "Install Tailscale? [y/N] " _ts
if [[ "$_ts" =~ ^[Yy]$ ]]; then
    info "Installing Tailscale..."
    yay -S --needed --noconfirm tailscale davfs2
    sudo systemctl enable --now tailscaled
    sudo tailscale set --operator=$USER
fi

# Enable SDDM
info "Enabling SDDM..."
sudo systemctl enable sddm

# Remove Plymouth boot animation
info "Removing Plymouth boot animation..."
sudo pacman -Rns --noconfirm plymouth cachyos-plymouth-bootanimation cachyos-plymouth-theme 2>/dev/null || true
sudo sed -i '/^HOOKS=/s/\bplymouth\b[[:space:]]*//' /etc/mkinitcpio.conf
sudo mkinitcpio -P

# Install fonts
info "Installing fonts..."
mkdir -p "$HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/_setup/fonts/." "$HOME/.local/share/fonts/"

# Rebuild font cache
info "Rebuilding font cache..."
fc-cache -fv

# Copy post-install script to home
info "Copying post-install script..."
cp "$DOTFILES_DIR/post-install.sh" "$HOME/post-install.sh"
sed -i "s|DOTFILES_DIR=.*|DOTFILES_DIR=\"$DOTFILES_DIR\"|" "$HOME/post-install.sh"
chmod +x "$HOME/post-install.sh"

# Reboot
echo
echo -e "${YELLOW}[!]${NC} ${BOLD}Run ~/post-install.sh after logging in to generate the theme and finish setup.${NC}"
echo
echo -e "${BOLD}Done. Rebooting in 5 seconds... (Ctrl+C to cancel)${NC}"
sleep 5
reboot
