#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
DOTFILES_DIR="$DIR/dotfiles"

# bash configs
cp $DOTFILES_DIR/.bashrc ~/.bashrc

# vim configs
cp $DOTFILES_DIR/.vimrc ~/.vimrc
cp $DOTFILES_DIR/.vim/Vimfile ~/.vim/Vimfile
cp -r $DOTFILES_DIR/.vim/colors ~/.vim/.
cp -r $DOTFILES_DIR/.vim/config ~/.vim/.

# tmux configs
cp $DOTFILES_DIR/.tmux.conf ~/.tmux.conf
