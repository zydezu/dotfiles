# Dotfiles

Personal dotfiles for mangowc on Arch Linux (my personal system uses CachyOS, which is based on Arch).

<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/9e6099c8-d5f8-461a-84ca-52f1cc18ad6f" />

## Overview

- **WM**: mangowc (Wayland)
- **Shell**: Fish
- **Terminal**: Alacritty
- **Theme**: Material You theme generated via [Matugen](https://github.com/InioX/matugen)

## Structure

Right, remove the codeblock — just paste the raw markdown directly into your README:

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

```
yay -S mangowm xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr swaybg swaync sway-audio-idle-inhibit-git hyprlock hypridle rofi waypaper grim slurp swappy gpu-screen-recorder alacritty fish zed nautilus actions-for-nautilus-git mpv mprisence pipewire wireplumber clipse cliphist wl-clipboard wl-clip-persist networkmanager dunst brightnessctl fastfetch bluetui wlctl matugen ttf-jetbrains-mono-nerd noto-fonts
```

### Copy Configs

```bash
./copy.sh
```

Run this script to copy the specified configs from `~/.config` to the dotfiles repo.

### Apply Theme

Use waypaper to change the wallpaper and generate the corresponding matugen theme from it, applying to all configured applications.

## Keybinds

| Key | Action |
|-----|--------|
| `Super + Return` | Alacritty |
| `Super + Space` | Rofi |
| `Super + L` | Lock |
| `Super + E` | Nautilus |
| `Super + Z` | Zed |
| `Super + V` | Clipse |
| `Super + B` | Helium Browser |
| `Print` | Screenshot the currently focused screen |
| `Alt + Print` | Screenshot all screens |
| `Ctrl + Print` | Screenshot a region |
| `Shift + Print` | Record the currently focused screen |
| `Ctrl + Shift + Print` | Screenshot |
| `Super + 1-9` | Switch tags |
| `Super + Shift + 1-9` | Move window to tag |

See `mango/binds.conf` for the full list.

Before starting mangowm, make sure `monitor.conf` is configured for your display setup to ensure the desktop loads correctly.

## Things To Check

When applying these dotfiles and logging into mango from your login manager, it may seem like things are not working. Check the configuration files in `mango/monitor.conf`, `mango/waybar/config.jsonc` and `hypr/hyprlock.conf`  specifically for setting a monitor output (you may need to change or remove lines like `DP-1`).
