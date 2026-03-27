#! /bin/bash
# set wallpaper
WALLPAPER="/home/zy/Pictures/archive/wallpapers/FlowerMoonV_1920x1080.png"

LOCK_ARGS="--clock \
--effect-blur 10x6 \
--effect-scale 0.5 \
--timestr \"%H:%M\" \
--datestr \"%d/%m/%Y\""

LOCK_CMD="swaylock -f -c 000000 --image \"$WALLPAPER\" $LOCK_ARGS"

swaybg -i "$WALLPAPER" &

fc-cache -f &
nautilus --gapplication-service &

# Start ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
fi

/usr/lib/xdg-desktop-portal-wlr &

# Watch clipboard and store history
wl-clip-persist --clipboard regular --reconnect-tries 0 &
wl-paste --type text --watch cliphist store &
clipse -listen &

# load waybar
waybar -c ~/.config/mango/waybar/config.jsonc -s ~/.config/mango/waybar/style.css &

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

swayidle -w \
  lock "$LOCK_CMD" \
  timeout 600 "$LOCK_CMD" \
  before-sleep "$LOCK_CMD" &
