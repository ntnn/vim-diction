" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	2
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

let s:save_cpo = &cpo
set cpo&vim

let s:lookup = {}

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

function s:parse_db(database)
    try
        let db_lines = readfile(a:database)
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

function diction#fill_lookup()
    for db in get(g:, 'diction_databases', [])
        call extend(s:lookup, s:parse_db(db))
    endfor
endfunction

function diction#check_buffer(bufnr)
    if empty(s:lookup)
        call diction#fill_lookup()
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
    " list of matches in buffer, each match is a list [lnum, col]
    let matches = []
    let lines = getbufline(a:bufnr, 0, "$")

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

    call s:log('Matching pattern "' . pattern . '"')

    for lnum in range(len(lines))
        " to allow multiline matches the current line has to be joined
        " with the next line - but at the same time this might result in
        " matches a line too early, so the resulting match column cannot
        " be greater than the length of the current line
        let line = lines[lnum]
        let linelen = strlen(line)
        let line = join([line,
                    \    get(lines, lnum + 1, '')
                    \   ])
        let col = match(line, pattern)

        if col != -1 && col < linelen
            call s:log('Found match in ' . lnum . ':' . col . ' ' . line)
            call add(matches, [lnum + 1, col + 1])
        endif
    endfor

    call s:log('Matched ' . len(matches) . ' occurences')
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
    else
        call setloclist(winnr(), [])
        call setloclist(winnr(), result)
    endif
endfunction

let &cpo = s:save_cpo
