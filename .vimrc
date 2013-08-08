set shell=bash
set background=dark
syntax on
set tabstop=2
set shiftwidth=2
set expandtab
set backspace=indent,eol,start
set number
set noswapfile
set hidden
set viminfo='100,h
map <C-d> :sh<CR>
set shell=bash\ --rcfile\ ~/.bash_vim
colorscheme jellybeans_modified
so ~/.vim/Vimfile
so ~/.vim/config/ctrlp.vim
so ~/.vim/config/language.vim
"so ~/.vim/config/ack.vim
