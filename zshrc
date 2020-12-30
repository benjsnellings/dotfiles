# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"
# eval `dircolors $HOME/.dir_colors/dircolors`


# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git sudo)

source $ZSH/oh-my-zsh.sh

# User configuration

export EDITOR="subl"

# export MANPATH="/usr/local/man:$MANPATH"

export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='mvim'
 fi


export PATH=$BRAZIL_CLI_BIN:$PATH

alias gll='git log --graph --all -n 20 --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset"'
alias glll='git log --graph --all -n 30 --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset"'
alias gllll='git log --graph --all -n 40 --pretty=format:"%Cblue%h%Creset [%Cgreen%ar%Creset] [%Cred%an%Creset] %s%C(yellow)%d%Creset"'
alias gpr='git branch -r | grep origin/ | grep -v 'async$' | grep -v 'mainline$' | grep -v HEAD | while read line; do git branch -d -r $line; done;'

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

# source /home/snellin/tools/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#source $HOME/tools/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH=$HOME/.toolbox/bin:$PATH
export PATH=$HOME/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=/opt/firefox/firefox:$PATH

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH=$HOME/.toolbox/bin:$PATH
