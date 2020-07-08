#!/bin/sh

killall polybar
# polybar topl &
# polybar topr &
polybar -c $HOME/.polybar/config topm &

