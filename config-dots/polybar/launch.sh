#!/usr/bin/env sh

## Add this to your wm startup file.

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $USER -x polybar >/dev/null; do sleep 1; done

# polybar -c ~/.config/polybar/config.ini main &

if type "xrandr"; then

  # Setup the main monitor 
  # First to launch recieves the system tray
  for m in $(xrandr --query | grep " primary" | cut -d" " -f1); do
    MONITOR=$m polybar -c ~/.config/polybar/config.ini main &
  done

  # Setup the supporting monitors
  for m in $(xrandr --query | grep " connected" | grep -v -e " primary" | cut -d" " -f1); do
    MONITOR=$m polybar -c ~/.config/polybar/config.ini secondary &
  done

else
  polybar -c ~/.config/polybar/config.ini main &
fi

