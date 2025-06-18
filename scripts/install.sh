#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
DOTFILES_DIR="$DIR/dotfiles"

# bash configs
if [ "$(uname -s)" == "Darwin" ]; then
  cp $DOTFILES_DIR/.bashrc ~/.bash_profile
fi

# vim configs
cp $DOTFILES_DIR/.vimrc ~/.vimrc
cp -r $DOTFILES_DIR/.vim ~/.

# tmux configs
cp $DOTFILES_DIR/.tmux.conf ~/.tmux.conf
