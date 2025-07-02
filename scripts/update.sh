#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
DOTFILES_DIR="$DIR/dotfiles"

# bash configs
if [ "$(uname -s)" == "Darwin" ]; then
  cp $DOTFILES_DIR/bashrc ~/.bash_profile
else
  cp $DOTFILES_DIR/bashrc ~/.bashrc
fi

# xdg_configs
rm -r ~/.config/nvim
cp -r $DOTFILES_DIR/config/nvim ~/.config/nvim

# vim configs
cp $DOTFILES_DIR/vimrc ~/.vimrc
cp $DOTFILES_DIR/vim/Vimfile ~/.vim/Vimfile
cp -r $DOTFILES_DIR/vim/colors ~/.vim/.
cp -r $DOTFILES_DIR/vim/config ~/.vim/.

# tmux configs
cp $DOTFILES_DIR/tmux.conf ~/.tmux.conf
