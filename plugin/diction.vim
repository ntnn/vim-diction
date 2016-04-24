" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	1
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

if !executable('diction')
    echomsg "Diction could not be found. Disabling vim-diction"
    finish
endif

if exists("g:loaded_diction")
    finish
endif
let g:loaded_diction = 1

let s:save_cpo = &cpo
set cpo&vim

command Diction call diction#wrap(1)
nnoremap <silent> <Plug>Diction :Diction<cr>
command LDiction call diction#wrap(0)
nnoremap <silent> <Plug>LDiction :LDiction<cr>

let &cpo = s:save_cpo
