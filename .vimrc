so ~/.vim/Vimfile
so ~/.vim/config/ctrlp.vim
so ~/.vim/config/syntax.vim
so ~/.vim/config/lightline.vim
so ~/.vim/config/vim_table_mode.vim
"so ~/.vim/config/syntax/r.vim
"so ~/.vim/config/ack.vim
"set mouse=a

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
"set iskeyword-=_

" Use The Silver Searcher https://github.com/ggreer/the_silver_searcher
if executable('ag')
 " Use Ag over Grep
 set grepprg=ag\ --nogroup\ --nocolor

 " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
 let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif

command PPjson %!python -m json.tool

"augroup vimrc
"  au BufReadPre * setlocal foldmethod=syntax
"  au BufWinEnter * if &fdm == 'syntax' | setlocal foldmethod=manual | endif
"augroup END
