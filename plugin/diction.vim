" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	4
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

if exists("g:loaded_diction")
    finish
endif
let g:loaded_diction = 1

let s:save_cpo = &cpo
set cpo&vim

let g:diction_db_sets = get(g:, 'diction_db_sets', {
            \ 'default': ['en', 'en-tech_words_to_avoid']
            \ })
let g:diction_active_set = get(g:, 'diction_active_set', 'default')

command Diction     call diction#fill_list(1, 0)
command DictionAdd  call diction#fill_list(1, 1)
nnoremap <silent>   <Plug>Diction :Diction<cr>
nnoremap <silent>   <Plug>DictionAdd :DictionAdd<cr>

command LDiction    call diction#fill_list(0, 0)
command LDictionAdd call diction#fill_list(0, 1)
nnoremap <silent>   <Plug>LDiction :LDiction<cr>
nnoremap <silent>   <Plug>LDictionAdd :LDictionAdd<cr>

command DictionLog call diction#write_log_to_file()
command DictionIndex call diction#reindex()

command -complete=customlist,diction#complete_db_sets -nargs=1 DictionSet call diction#set_active_set(<q-args>)

let &cpo = s:save_cpo
