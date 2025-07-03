#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
DOTFILES_DIR="$DIR/dotfiles"

# bash configs
if [ "$(uname -s)" == "Darwin" ]; then
  cp ~/.bash_profile $DOTFILES_DIR/bashrc
else
  cp ~/.bashrc $DOTFILES_DIR/bashrc
fi

# xdg_configs
rm -r $DOTFILES_DIR/config/nvim
cp -r ~/.config/nvim $DOTFILES_DIR/config/nvim

# vim configs
cp ~/.vimrc $DOTFILES_DIR/vimrc
cp ~/.vim/Vimfile $DOTFILES_DIR/vim/Vimfile
cp ~/.vim/colors/*.vim $DOTFILES_DIR/vim/colors/.
cp ~/.vim/config/*.vim $DOTFILES_DIR/vim/config/.

# tmux configs
cp ~/.tmux.conf $DOTFILES_DIR/tmux.conf
