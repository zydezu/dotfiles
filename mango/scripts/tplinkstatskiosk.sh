#!/bin/bash
cog --platform=x11 http://sunny:8090/?kiosk=1 &
~/.config/mango/scripts/movecogwin.sh 700 765
~/.config/mango/scripts/watchkiosk.sh
