#!/bin/bash
cd ~/.config
shopt -s dotglob

allowed_dirs=(actions-for-nautilus alacritty environment.d fastfetch fish gpu-screen-recorder mango matugen mprisence mpv rofi swaync xdg-desktop-portal zed)

for dir in */; do
    for allowed in "${allowed_dirs[@]}"; do
        if [[ "$dir" == "$allowed/" ]]; then
            cp -r "$dir" /home/zy/Documents/projects/coding/dotfiles/
            break
        fi
    done
done
