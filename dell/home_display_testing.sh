#!/bin/bash

xrandr --output eDP-1 --mode 3840x2400 --pos 0x0 --auto \
 --output DP-3 --rate 60.00 --mode 3840x2160 --pos 3840x0 --auto \
 --output DP-1 --rate 59.94 --mode 1920x1080 --pos 7680x0 --auto \
 --scale 2x2 --panning 3840x2160+7680+0 \
 --fb 11520x2400
nitrogen --restore
