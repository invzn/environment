#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# bash configs
cp $DIR/.bash_login ~/.bash_login

# vim configs
cp $DIR/.vimrc ~/.vimrc
cp -r $DIR/.vim ~/.

# tmux configs
cp $DIR/.tmux.conf ~/.tmux.conf
cp -r $DIR/.tmux ~/.

# git configs
cp -r $DIR/.gitconfig ~/.gitconfig

# remove existing vundle install
rm -rf ~/.vim/bundle/vundle

# install vundle
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

# vundle install
vim +BundleInstall +qall
