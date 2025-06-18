let g:netrw_liststyle=3
let g:netrw_banner=0
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
"set nofixendofline
set viminfo='100,h
set timeoutlen=50
set shell=bash\ --rcfile\ ~/.bash_vim
colorscheme jellybeans_modified

so ~/.vim/Vundlefile
"so ~/.vim/config/ack.vim
so ~/.vim/config/ctrlp.vim
so ~/.vim/config/syntax.vim
so ~/.vim/config/lightline.vim
"so ~/.vim/config/vim_table_mode.vim
"so ~/.vim/config/syntax/r.vim
"set mouse=a
