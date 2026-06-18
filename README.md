# Dotfiles

Personal dotfiles for mangowc on Arch Linux (my personal system uses CachyOS, which is based on Arch).

<img width="2560" height="1440" alt="image" src="https://raw.githubusercontent.com/zydezu/dotfiles/main/screenshot.png" />

## Overview

- **WM**: mangowc (Wayland)
- **Shell**: Fish
- **Terminal**: Alacritty
- **Theme**: Material You theme generated via [Matugen](https://github.com/InioX/matugen)
- **Icons**: [Neuwaita](https://github.com/RusticBard/neuwaita)

## Structure

| Directory | Description |
|-----------|-------------|
| `actions-for-nautilus/` | [Configurable right click for nautilus](https://github.com/bassmanitram/actions-for-nautilus) |
| `alacritty/` | [Terminal](https://github.com/alacritty/alacritty) |
| `bluetui/` | [TUI bluetooth manager](https://github.com/pythops/bluetui) |
| `clipse/` | [Clipboard manager](https://github.com/savedra1/clipse) |
| `environment.d/` | Environment variables |
| `fastfetch/` | [System info](https://github.com/fastfetch-cli/fastfetch) |
| `fish/` | [Shell](https://github.com/fish-shell/fish-shell) |
| `gpu-screen-recorder/` | [Screen recording](https://github.com/BrycensRanch/gpu-screen-recorder-git-copr) |
| `hypr/` | [Hyprlock & hypridle](https://github.com/hyprwm/hyprlock) |
| `mango/` | [Wayland compositor](https://github.com/mangowm/mango) |
| `matugen/` | [Color theming](https://github.com/InioX/matugen) |
| `mprisence/` | [Discord rich presence](https://github.com/lazykern/mprisence) |
| `mpv/` | [Video player](https://github.com/mpv-player/mpv) |
| `rofi/` | [App launcher](https://github.com/davatorium/rofi) |
| `swappy/` | [Screenshot markup](https://github.com/jtheoof/swappy) |
| `swaync/` | [Notification center](https://github.com/ErikReider/SwayNotificationCenter) |
| `waypaper/` | [Wallpaper](https://github.com/anufrievroman/waypaper) |
| `wlctl/` | [TUI Wi-Fi manager](https://github.com/aashish-thapa/wlctl) |
| `xdg-desktop-portal/` | [Portal config](https://github.com/flatpak/xdg-desktop-portal) |
| `zed/` | [Code editor](https://github.com/zed-industries/zed) |

## Installation

### Installation on Arch

```bash
yay -S \
    `# compositor & bar` \
    mangowm waybar \
    `# portals` \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
    `# wallpaper, notifications & lock` \
    swaybg waypaper swaync sway-audio-idle-inhibit-git hyprlock hypridle xfce-polkit \
    `# launcher & screenshot` \
    rofi rofi-power-menu grim slurp wayfreeze-git swappy \
    `# theming` \
    matugen adw-gtk-theme adwaita-fonts ttf-jetbrains-mono-nerd noto-fonts \
    qt5ct qt6ct qt6-declarative qt6-svg \
    qt5-quickcontrols qt5-quickcontrols2 qt5-declarative qt5-graphicaleffects \
    `# terminal, shell & editors` \
    alacritty fish zed \
    `# apps` \
    helium-browser-bin nautilus actions-for-nautilus-git mpv mprisence \
    `# audio` \
    pipewire wireplumber wiremix \
    `# clipboard` \
    clipse cliphist wl-clipboard wl-clip-persist \
    `# system utilities` \
    networkmanager brightnessctl gpu-screen-recorder dunst fastfetch github-cli \
    `# tui tools` \
    bluetui wlctl \
    `# display manager` \
    sddm xorg-server
```

### Copy Configs

```bash
./copy.sh
```

Run this script to copy the specified configs from `~/.config` to the dotfiles repo.

### Apply Theme

Use waypaper to change the wallpaper and generate the corresponding matugen theme from it, applying to all configured applications.

## Keybinds

### Apps

Binds to launch various applications.

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>Return</kbd> | Launch alacritty |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Launch rofi (app launcher) |
| <kbd>Super</kbd> + <kbd>l</kbd> | Lock session |
| <kbd>Super</kbd> + <kbd>b</kbd> | Launch Helium browser |
| <kbd>Super</kbd> + <kbd>e</kbd> | Launch Nautilus |
| <kbd>Super</kbd> + <kbd>z</kbd> | Launch Zeditor |
| <kbd>Super</kbd> + <kbd>v</kbd> | Launch clipse |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Esc</kbd> | Launch btop |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd> | Launch color picker |

### Screenshotting

Screenshots use grim and wl-copy, whilst screenrecording uses gpu-screen-recorder.

| Key | Action |
|-----|--------|
| <kbd>Print</kbd> | Screenshot (active screen) |
| <kbd>Alt</kbd> + <kbd>Print</kbd> | Screenshot (all screens) |
| <kbd>Ctrl</kbd> + <kbd>Print</kbd> | Screenshot (select region) |
| <kbd>Shift</kbd> + <kbd>Print</kbd> | Screen record (active screen) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Print</kbd> | Screen record (select region) |

### Tags

Tags are numbered from 1 to 9, they act like separate workspaces.

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>Left</kbd> | Switch tags to the left |
| <kbd>Super</kbd> + <kbd>Right</kbd> | Switch tags to the right |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Left</kbd> | Move window to the left tag |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Right</kbd> | Move window to the right tag |
| <kbd>Super</kbd> + <kbd>1-9</kbd> | Switch to numbered tag (follow the window) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1-9</kbd> | Send window to numbered tag (don't follow the window) |

### Window Management

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>q</kbd> | Kill focused client |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | Toggle overview |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Focus next window |
| <kbd>Super</kbd> + <kbd>g</kbd> | Toggle global |
| <kbd>Super</kbd> + <kbd>o</kbd> | Toggle overlay |
| <kbd>Super</kbd> + <kbd>f</kbd> | Toggle floating |
| <kbd>Super</kbd> + <kbd>t</kbd> | Switch layout |
| <kbd>Super</kbd> + <kbd>m</kbd> | Minimize window |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>m</kbd> | Restore minimized |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>m</kbd> | Toggle scratchpad |

### Window Movement / Swap

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>←↑↓→</kbd> | Exchange client with neighbour |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Left</kbd> | Send window to left monitor |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Right</kbd> | Send window to right monitor |
| <kbd>Super</kbd> + <kbd>Left click</kbd> | Move window |
| <kbd>Super</kbd> + <kbd>Right click</kbd> | Resize window |

### Misc

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>r</kbd> | Reload config |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>w</kbd> | Reload waybar |

### Gaps

| Key | Action |
|-----|--------|
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>x</kbd> | Increase gaps |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>z</kbd> | Decrease gaps |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>r</kbd> | Toggle gaps |

### Volume / Media Keys

| Key | Action |
|-----|--------|
| <kbd>XF86AudioRaiseVolume</kbd> | Volume +5% |
| <kbd>XF86AudioLowerVolume</kbd> | Volume -5% |
| <kbd>XF86AudioMute</kbd> | Toggle mute |
| <kbd>XF86AudioPlay</kbd> | Play / pause |
| <kbd>XF86AudioNext</kbd> | Next track |
| <kbd>XF86AudioPrev</kbd> | Previous track |
| <kbd>XF86AudioStop</kbd> | Stop |
| <kbd>XF86MonBrightnessUp</kbd> | Brightness +5% |
| <kbd>XF86MonBrightnessDown</kbd> | Brightness -5% |

### Gestures (3-finger)

| Gesture | Action |
|---------|--------|
| Swipe right | View to left |
| Swipe left | View to right |
| Swipe up | Toggle overview |
| Swipe down | Toggle overview |

### Settings

| Setting | Value |
|---------|-------|
| Keyboard layout | gb (compose on Menu) |
| Mouse natural scroll | Off |
| Trackpad natural scroll | On |
| Disable while typing | Off |

See `mango/binds.conf` for the full list.

Before starting mangowm, make sure `monitor.conf` is configured for your display setup to ensure the desktop loads correctly.

## Things To Check

When applying these dotfiles and logging into mango from your login manager, it may seem like things are not working. Check the configuration files in `mango/monitor.conf`, `mango/waybar/config.jsonc`, `swaync/config.jsonc`, and `hypr/hyprlock.conf` specifically for setting a monitor output (you may need to change or remove lines like `DP-1`).
