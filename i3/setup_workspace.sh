#!/bin/bash

# i3-msg "workspace 1; append_layout ~/.i3/workspace-layouts/chrome-workspace.json"
# i3-msg "exec --no-startup-id chromium-browser"

# i3-msg "workspace 6; append_layout ~/.i3/workspace-layouts/intellij-workspace.json"
# i3-msg "exec --no-startup-id ~/.local/share/umake/ide/idea/bin/idea.sh"

# i3-msg "workspace 9; append_layout ~/.i3/workspace-layouts/background-workspace.json"
# i3-msg "exec --no-startup-id spotify"
# i3-sensible-terminal

# 34 Inch Monitor
# i3-msg "workspace 3; append_layout ~/.i3/workspace-layouts/34-subl-workspace.json"
# i3-msg "workspace 3; exec --no-startup-id subl -n"
# i3-msg "workspace 3; exec --no-startup-id subl -n"
# i3-msg "workspace 3; exec i3-sensible-terminal"
# i3-msg "workspace 3; exec i3-sensible-terminal"

# i3-msg "workspace 4; append_layout ~/.i3/workspace-layouts/34-idea-workspace.json"
# i3-msg "workspace 4; exec --no-startup-id /home/local/ANT/snellin/.idea/idea.sh"
# i3-msg "workspace 4; exec i3-sensible-terminal -e ssh Developer-Desktop"

# i3-msg "workspace 8; exec --no-startup-id /home/local/ANT/snellin/workspace-local/Chime/src/UCBuzzExpressElectron/dist/linux-unpacked/amazonchime"
# i3-msg "workspace 8; exec --no-startup-id thunderbird"

i3-msg "workspace 8; append_layout ~/.i3/workspace-layouts/34-comms-workspace.json"
i3-msg "workspace 8; exec --no-startup-id ~/workspace-local/Chime/src/UCBuzzExpressElectron/dist/linux-unpacked/amazonchime"
i3-msg "workspace 8; exec --no-startup-id thunderbird"



# i3-msg "workspace 9; append_layout ~/.i3/workspace-layouts/34-spotify-workspace.json"
i3-msg "workspace 9; exec spotify"
i3-msg "workspace 9; exec gnome-terminal -e /home/local/ANT/snellin/unison-forever.sh "

# i3-msg "workspace 4"