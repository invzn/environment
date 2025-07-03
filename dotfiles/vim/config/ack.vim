let grepprg_bak=&grepprg
let grepformat_bak=&grepformat
let shellpipe_bak=&shellpipe
try
  let &shellpipe="&>"
  let &grepprg=g:ackprg
  let &grepformat=g:ackformat
  silent execute a:cmd . " " . escape(l:grepargs, '|')
finally
  let &shellpipe=shellpipe_bak
  let &grepprg=grepprg_bak
  let &grepformat=grepformat_bak
endtry
