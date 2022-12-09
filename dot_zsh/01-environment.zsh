# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# ZSH_THEME="awesomepanda"
ZSH_THEME=""

plugins=(git sudo docker zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR="vim"
export LANG=en_US.UTF-8

# Starship prompt
eval "$(starship init zsh)"
