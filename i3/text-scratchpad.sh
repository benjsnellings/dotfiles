#!/bin/bash

tmp_file=$(mktemp)
urxvt -name __text_scratchpad -e $SHELL -lc "sleep 0.1 && vim -c startinsert -c 'setlocal spell' ${tmp_file}" && xclip -selection clipboard < $tmp_file
