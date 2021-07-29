#!/bin/bash

# Some setup specific to the DELL XPS 9500 setup

## Setup Natural Scrolling: Look for "Dell Touchpad" entry
xinput set-prop 13 'libinput Natural Scrolling Enabled' 1
xinput set-prop 14 'libinput Natural Scrolling Enabled' 1

## Set caps lock to run escape
xcape -e "Mode_switch=Escape"

## Configure Solaar
solaar config 2 dpi 3000
# solaar config 2 hires-smooth-resolution true
killall imwheel && imwheel -b "4 5 6 7"

## Configure Keyboard repeat speed
xset r rate 200 80

notify-send "Completed Dell Setup"
