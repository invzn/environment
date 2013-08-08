#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# bash configs
cp ~/.bash_login $DIR/.bash_login
cp ~/.bash_vim $DIR/.bash_vim

# vim configs
cp ~/.vimrc $DIR/.vimrc
cp ~/.vim/Vimfile $DIR/.vim/Vimfile
cp -r ~/.vim/colors $DIR/.vim/.
cp -r ~/.vim/config $DIR/.vim/.

# tmux configs
cp ~/.tmux.conf $DIR/.tmux.conf
cp -r ~/.tmux $DIR/.

# git configs
cp -r ~/.gitconfig $DIR/.gitconfig
