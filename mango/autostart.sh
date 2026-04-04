#! /bin/bash
LOCK_ARGS="--clock \
--effect-blur 10x6 \
--effect-scale 0.5 \
--timestr \"%H:%M\" \
--datestr \"%d/%m/%Y\""

LOCK_CMD="swaylock -f -c 000000 --image \"$WALLPAPER\" $LOCK_ARGS"

# Run the desktop portal (URI/screenshare)
/usr/lib/xdg-desktop-portal-wlr >/dev/null 2>&1 &

fc-cache -f >/dev/null 2>&1 &
nautilus --gapplication-service >/dev/null 2>&1 &

# keep clipboard content
wl-clip-persist --clipboard regular --reconnect-tries 0 >/dev/null 2>&1 &
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
clipse -listen

# top bar
waybar -c ~/.config/mango/waybar/config.jsonc -s ~/.config/mango/waybar/style.css >/dev/null 2>&1 &

# wallpaper
waypaper --restore >/dev/null 2>&1 &

swayidle -w \
  lock "$LOCK_CMD" \
  timeout 600 "$LOCK_CMD" \
  before-sleep "$LOCK_CMD" >/dev/null 2>&1 &

# Permission authentication
/usr/lib/xfce-polkit/xfce-polkit >/dev/null 2>&1 &

# Inhibit locking by audio
sway-audio-idle-inhibit >/dev/null 2>&1 &

# load autostart programs
for desktop_file in ~/.config/autostart/*.desktop; do
    if [ -f "$desktop_file" ]; then
        # Extract the Exec line
        exec_line=$(grep -E "^Exec=" "$desktop_file" | head -1 | sed 's/^Exec=//')

        # Remove field codes like %U, %F, etc. (simplified)
        clean_exec=$(echo "$exec_line" | sed 's/%[a-zA-Z]//g')

        # Execute the command in background
        eval "$clean_exec" &
    fi
done
