#!/bin/bash
cd ~/.config
shopt -s dotglob
for dir in */; do
    cp -r "$dir" /home/zy/Documents/projects/coding/dotfiles/
done