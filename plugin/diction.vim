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

" Formatters:
" 1. g:diction_formatter
" 2. formatprg
" 3. 'fmt -t' from coreutils
let s:formatter = get(g:, 'diction_formatter', &formatprg)
if empty(s:formatter)
    let s:formatter = 'fmt -t'
endif
if !executable(get(split(s:formatter, ' '), 0))
    echomsg "No formatter found, disabling formatting of long lines"
else
    let g:diction_formatter = s:formatter
endif

" Databases:
" 1. shipped
" 2. user defined
let s:databases = glob(expand('<sfile>:p:h:h') . '/database/*', 0, 1)
"                                                               |  +- return list
"                                                               +- nosuffix
call extend(s:databases, get(g:, 'diction_databases', []))
let g:diction_databases = s:databases

command Diction call diction#fill_list(1)
nnoremap <silent> <Plug>Diction :Diction<cr>
command LDiction call diction#fill_list(0)
nnoremap <silent> <Plug>LDiction :LDiction<cr>
command DictionLog call diction#write_log_to_file()

let &cpo = s:save_cpo
