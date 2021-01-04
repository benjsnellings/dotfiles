#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables
dir=~/dotfiles/config-dots                  # dotfiles directory
olddir=~/old_dotfiles/old_config_dotfiles	# old dotfiles backup directory

# list of files/folders to symlink in homedir
files="sway compton polybar solaar"    

##########

# create old_dotfiles in homedir
echo "Creating $olddir for backup of any existing dotfiles in .config"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to old_dotfiles directory, then create symlinks
for file in $files; do
    echo "Moving any existing dotfiles from .config/ to old_dotfiles"
    mv ~/.config/$file $olddir
    echo "Creating symlink to $file in .config directory."
    ln -sTf $dir/$file ~/.config/$file
done

