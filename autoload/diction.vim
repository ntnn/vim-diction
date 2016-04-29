" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	3
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

let s:save_cpo = &cpo
set cpo&vim

let s:lookup = {}
let s:plugin_path = expand('<sfile>:p:h:h')
let s:messages = []

function s:mess(level, message)
    let prefix = 'vim-diction:' . expand('<sfile>') . ':'
    if type(a:message) == type([])
        for mess in a:message
            call s:mess(level, '  ' . mess)
        endfor
        return
    else
        let message = prefix . a:message
    endif

    if a:level == 'debug' && get(g:, 'diction_debug', 0)
        echomsg message
    elseif a:level == 'error'
        echohl Error
        echomsg message
        echohl None
    else
        echomsg message
    endif
    call add(s:messages, message)
endfunction

function diction#write_log_to_file()
    let mess = [
                \ 'Databases: ' . join(get(g:, 'diction_databases', [])),
                \ 'Dictions: ' . len(keys(s:lookup)),
                \ ]
    call extend(mess, s:messages)
    call writefile(mess, 'vim-diction.log', '')
endfunction

function s:parse_db(db_name)
    let db_path = expand(a:db_name)
    if !filereadable(db_path)
        let db_path = s:plugin_path . '/database/' . a:db_name
    endif

    try
        let db_lines = readfile(db_path)
    catch /E484/
        call s:mess('error', 'Database ' . db_path . ' does not exist.')
        return
    endtry

    let db = {}

    for line in db_lines
        if line[0] == '#' || line == ''
            " ignore comments and empty lines
            continue
        endif

        let splitted = split(line, '\t')

        if len(splitted) == 1
            let problem = line
            let solution = 'Bad diction'
        elseif len(splitted) == 2
            let [problem, solution] = splitted
        else
            call s:mess('debug', 'Line ' . index(db_lines, line)  . ':"' . line . '" does not match spec')
            continue
        endif

        let db[problem] = solution
    endfor

    return db
endfunction

function s:get_active_set()
    let setname = get(l:, 'diction_active_set',
                \ get(g:, 'diction_active_set', 'default')
                \ )

    return get(g:diction_db_sets, setname, [])
endfunction

function diction#set_active_set(set)
    if index(keys(g:diction_db_sets), a:set) == -1
        call s:mess('error', 'Given set ' . a:set . ' not in defined sets')
        return
    endif
    let g:diction_active_set = a:set
    call diction#reindex()
endfunction

function diction#complete_db_sets(ArgLead, CmdLine, CursorPos)
    let completions = []

    if len(split(a:CmdLine, ' ')) > 1
        " DictionSet only takes one argument
        return []
    endif

    for name in keys(g:diction_db_sets)
        if name =~ a:ArgLead
            call add(completions, name)
        endif
    endfor

    return completions
endfunction

function diction#reindex()
    let s:lookup = {}
    for db in s:get_active_set()
        call extend(s:lookup, s:parse_db(db))
    endfor
endfunction

function diction#check_buffer(bufnr)
    if empty(s:lookup)
        call diction#reindex()
    endif

    " list of matches, each match is a dictionary, that setqflist()
    " would accept
    let matches = []


    for problem in keys(s:lookup)
        for matched in s:matchlist(problem, a:bufnr)
            call add(matches, {
                        \ 'bufnr': a:bufnr,
                        \ 'lnum': matched[0],
                        \ 'col': matched[1],
                        \ 'text': problem . ' -> ' . s:lookup[problem]
                        \ }
                        \ )
        endfor
    endfor

    return sort(matches, function('s:sort_matches'))
endfunction

function s:matchlist(pattern, bufnr)
    if match(a:pattern, ' ') != -1
        " if pattern contains a space the space has to be substituted
        " for [:blank:]
        let pattern = substitute(
                    \   a:pattern,
                    \   ' ',
                    \   escape('\s\+', '\[]'),
                    \   'g'
                    \ )
    else
        " otherwise it is a single word and has to be handles as such
        let pattern = '\<' . a:pattern . '\>'
    endif
    let pattern = '\c' . pattern
    call s:mess('debug', 'Matching pattern "' . pattern . '"')

    let pos_save = getcurpos()
    call setpos('.', [a:bufnr, 1, 1, 0])

    let matches = []

    let flags = 'Wz'
    " W - don't wrap around at EOF
    " z - start search at cursor col instead of zero

    let m = searchpos(pattern, flags)
    while m != [0, 0]
        call s:mess('debug', 'Found match in ' . string(m))
        call add(matches, m)
        let m = searchpos(pattern, flags)
    endwhile

    call s:mess('debug', 'Matched ' . len(matches) . ' occurences')

    call setpos('.', pos_save)

    return matches
endfunction

function s:sort_matches(a, b)
    if 0 != a:a.bufnr - a:b.bufnr
        return a:a.bufnr - a:b.bufnr
    endif

    if 0 != a:a.lnum - a:b.lnum
        return a:a.lnum - a:b.lnum
    endif

    return a:a.col - a:b.col
endfunction

function diction#fill_list(qf, add)
    let result = diction#check_buffer(bufnr('%'))
    if !a:add
        if a:qf
            call setqflist([])
        else
            call setqflist(winnr(), [])
        endif
    endif

    if a:qf
        call setqflist(result, 'a')
        if get(g:, 'diction_open_window', 1)
            copen
        endif
    else
        call setloclist(winnr(), result, 'a')
        if get(g:, 'diction_open_window', 1)
            lopen
        endif
    endif
endfunction

let &cpo = s:save_cpo
