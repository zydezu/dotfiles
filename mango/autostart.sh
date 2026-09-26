#!/bin/bash

# Run the desktop portal (URI/screenshare)
/usr/lib/xdg-desktop-portal-wlr >/dev/null 2>&1 &

# Screen locking and sleeping
hypridle >/dev/null 2>&1 &

# Inhibit locking by audio
sway-audio-idle-inhibit >/dev/null 2>&1 &

# wallpaper
waypaper --restore >/dev/null 2>&1 &

# top bar
waybar -c ~/.config/mango/waybar/config.jsonc -s ~/.config/mango/waybar/style.css >/dev/null 2>&1 &

nautilus --gapplication-service >/dev/null 2>&1 &

# keep clipboard content
wl-clip-persist --clipboard regular --reconnect-tries 0 >/dev/null 2>&1 &
clipse -listen &

# Suppress notifications in fullscreen
~/.config/mango/scripts/fullscreendnd.sh >/dev/null 2>&1 &

# load autostart programs (respects Hidden/NoDisplay/OnlyShowIn/NotShowIn/TryExec)
(
    sleep 0.5
    dex -a -e mango >/dev/null 2>&1
) &

# Close some app windows on startup (they stay in the tray)
~/.config/mango/scripts/closeapps.sh >/dev/null 2>&1 &
