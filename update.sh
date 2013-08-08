#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# bash configs
cp $DIR/.bash_login ~/.bash_login

# vim configs
cp $DIR/.vimrc ~/.vimrc
cp $DIR/.vim/Vimfile ~/.vim/Vimfile
cp -r $DIR/.vim/colors ~/.vim/.
cp -r $DIR/.vim/config ~/.vim/.

# tmux configs
cp $DIR/.tmux.conf ~/.tmux.conf
cp -r $DIR/.tmux ~/.

# git configs
cp -r $DIR/.gitconfig ~/.gitconfig
