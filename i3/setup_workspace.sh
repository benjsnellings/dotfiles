#!/bin/bash

i3-msg "workspace 1; append_layout ~/.i3/workspace-1.json"
i3-sensible-terminal 
i3-sensible-terminal 
i3-sensible-terminal

i3-msg "workspace 2; append_layout ~/.i3/workspace-2.json"
i3-msg "exec --no-startup-id firefox"
i3-msg "exec --no-startup-id ~/Documents/IntelliJ/idea-IC-163.11103.6/bin/idea.sh"

i3-msg "workspace 3; append_layout ~/.i3/workspace-3.json"
i3-msg "exec --no-startup-id slack"

i3-msg "workspace 4"
i3-msg "exec --no-startup-id spotify"
