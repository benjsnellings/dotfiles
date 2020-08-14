#!/bin/bash

xrandr --fb 12480x2700 \
 --output eDP-1 --mode 3840x2400 --pos 0x0 --scale 0.9999x0.9999 \
 --output DP-1-3 --mode 3840x2160 --rate 60.00 --pos 3840x0 --scale 1.25x1.25 \
 --output DP-2 --mode 1920x1080 --scale 2x2 --pos 8640x0 --rate 59.94 --panning 3840x2160+8640+0
nitrogen --restore
~/.config/polybar/launch.sh


