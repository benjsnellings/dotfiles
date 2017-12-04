#!/bin/bash
scrot /tmp/screen.png
convert /tmp/screen.png -scale 10% -scale 1000% /tmp/screen.png
[[ -f $1 ]] && convert /tmp/screen.png $1 -gravity east -region 10x10+40 -composite -matte /tmp/screen.png
#xset dpms 600 
i3lock -i /tmp/screen.png --debug >> ~/.i3/lockLog.txt
rm /tmp/screen.png
