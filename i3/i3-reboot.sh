#!/bin/bash

i3-msg "restart"
sleep .5
~/dotfiles/polybar/run_polybar.sh
