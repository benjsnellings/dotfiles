#!/bin/bash


tail -f -n 0 .zsh_history| while read line; do echo  "$line" | sed 's/.*;//' | festival --tts 
done


# For Mac
# tail -f -n 0 .zsh_history| while read line; do echo  "$line" | sed 's/.*;//' | say
# done