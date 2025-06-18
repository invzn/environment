let g:ctrlp_map = ''
let g:ctrlp_cmd = ''
let g:ctrlp_use_caching = 1
let g:ctrlp_show_hidden = 1
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_cache_dir = $HOME.'/.ctrlp/cache'
let g:ctrlp_open_new_file = 'r'
let g:ctrlp_prompt_mappings = {
  \'CreateNewFile()': ['<c-o>'],
  \'ToggleRegex()': ['<F5>'],
  \'PrtClearCache()': ['<c-r>']
\}

let mapleader = ";"
map <C-p> :CtrlP<CR>
map <C-l> :CtrlPBuffer<CR>

set wildignore+=*/tmp/*,*.so,*.swp,*.zip,vendor
