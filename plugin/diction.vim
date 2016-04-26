" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	2
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

if exists("g:loaded_diction")
    finish
endif
let g:loaded_diction = 1

let s:save_cpo = &cpo
set cpo&vim

command Diction call diction#fill_list(1)
nnoremap <silent> <Plug>Diction :Diction<cr>
command LDiction call diction#fill_list(0)
nnoremap <silent> <Plug>LDiction :LDiction<cr>
command DictionLog call diction#write_log_to_file()
command DictionIndex call diction#reindex()

let &cpo = s:save_cpo
