alias gll='git log --graph --all -n 20 --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset"'
alias glll='git log --graph --all -n 30 --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset"'
alias gllll='git log --graph --all -n 40 --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset"'
alias glp='git log --graph -n 20  --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset" HEAD'
alias moi='chezmoi'

alias root='cd $(git rev-parse --show-cdup)'

# Brazil Alias'
alias bb=brazil-build
alias br=brazil-build-rainbow
alias bbc='bb clean'
alias bba='brazil-build apollo-pkg'
alias bre='brazil-runtime-exec'
alias brc='brazil-recursive-cmd'
alias bws='brazil ws'
alias bwsuse='bws use --gitMode -p'
alias bwscreate='bws create -n'
alias brc=brazil-recursive-cmd
alias bbr='brc brazil-build'
alias bball='brc --allPackages'
alias bbb='brc --allPackages brazil-build'
alias bbbc='bball --reverse --continue brazil-build clean'
alias bbra='bbr apollo-pkg'
alias sam='brazil-build-tool-exec sam $1'
alias adaAdmin='function _admin(){ ada credentials update --account=$1 --provider conduit --role=IibsAdminAccess-DO-NOT-DELETE };_admin'

alias mwinit='mwinit -o --aea'
alias auth='kinit && mwinit'
alias isengard='isengardcli'

### EDA Alias'
alias ebb='eda build brazil-build'
alias ebbb='eda build brazil-build build'

