#!/bin/bash

python3 $HOME/.i3/screen_setup.py
# python3 $HOME/.i3/setup_workspace.py
nitrogen --restore
~/.config/polybar/launch.sh
~/dotfiles/dell/dell_setup.sh

