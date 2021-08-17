#!/bin/bash

# Setup Display and Set monitor names to XResources
python3 $HOME/.i3/screen_setup.py

# Reload I3WM with new displays
i3-msg "reload"
i3-msg "restart"

# Setup premade workspaces
# python3 $HOME/.i3/setup_workspace.py

# Relauch Polybar 
~/.config/polybar/launch.sh


# Restore the wallpaper
nitrogen --restore

# Restore DELL specific settings for good measure
~/dotfiles/dell/dell_setup.sh

