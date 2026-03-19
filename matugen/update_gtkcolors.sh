#!/usr/bin/env bash

# toggle to force GTK reload
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
sleep 0.1
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"

systemctl --user restart xdg-desktop-portal-gtk
