" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	2
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

let s:save_cpo = &cpo
set cpo&vim

let s:lookup = {}
let s:plugin_path = expand('<sfile>:p:h:h')

function s:log(message)
    let prefix = 'vim-diction:' . expand('<sfile>') . ':'
    if get(g:, 'diction_debug', 0)
        if type(a:message) == type([])
            " check if message is a list
            call s:log('List logged:')
            for mess in a:message
                echomsg prefix . '  ' . mess
            endfor
        else
            echomsg prefix . a:message
        endif
    endif
endfunction

function s:error(message)
    echohl Error
    echomsg  'vim-diction:' . expand('<sfile>') . ':' . a:message
    echohl None
endfunction

function diction#write_log_to_file()
    redir => mess
        silent messages
    redir END
    let mess = split(mess, '\n')
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
        call s:error('Database ' . a:database . ' does not exist.')
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
            call s:log('Line ' . index(db_lines, line)  . ':"' . line . '" does not match spec')
            continue
        endif

        let db[problem] = solution
    endfor

    return db
endfunction

function diction#reindex()
    let s:lookup = {}
    for db in get(g:, 'diction_databases', ['en', 'tech_words_to_avoid'])
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

    let pos_save = getcurpos()
    call setpos('.', [a:bufnr, 1, 1, 0])

    let matches = []

    let flags = 'Wz'
    " W - don't wrap around at EOF
    " z - start search at cursor col instead of zero

    let m = searchpos(pattern, flags)
    while m != [0, 0]
        call s:log('Found match in ' . string(m))
        call add(matches, m)
        let m = searchpos(pattern, flags)
    endwhile

    call s:log('Matched ' . len(matches) . ' occurences')

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

function diction#fill_list(qf)
    let result = diction#check_buffer(bufnr('%'))
    if a:qf
        call setqflist([])
        call setqflist(result)
        if get(g:, 'diction_open_window', 1)
            copen
        endif
    else
        call setloclist(winnr(), [])
        call setloclist(winnr(), result)
        if get(g:, 'diction_open_window', 1)
            lopen
        endif
    endif
endfunction

let &cpo = s:save_cpo
