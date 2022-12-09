# Load fzf

FZF_DIR="$HOME/.fzf"

if [ ! -d "$FZF_DIR" ]
then
    echo "fzf is not installed"
else
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

