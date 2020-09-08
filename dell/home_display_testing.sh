#!/bin/bash


# xrandr --prop | grep -A3 " connected " 

 xrandr --fb 11520x2400 \
  --output eDP-1 --mode 3840x2400 --pos 0x0 --scale 0.9999x0.9999 \
  --output DP-6 --primary --mode 3840x2160 --rate 60.00 --pos 3840x0 --scale 0.9999x0.9999 \
  --output DP-2 --mode 1920x1080 --scale 2x2 --pos 7680x0 --rate 59.94 --panning 3840x2160+7680+0
# nitrogen --restore
# ~/.config/polybar/launch.sh

