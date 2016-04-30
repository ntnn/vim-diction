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
    " Logger function.
    "
    " level: log level, either 'debug' or 'error'. Other is printed
    "   verbatim
    " message: Message to print. String or list.

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
        let v:errmsg = a:message
        echohl None
    else
        echomsg message
    endif
    call add(s:messages, message)
endfunction

function diction#write_log_to_file()
    " Write messages to 'vim-diction.log'
    let mess = [
                \ 'Databases: ' . join(get(g:, 'diction_databases', [])),
                \ 'Dictions: ' . len(keys(s:lookup)),
                \ ]
    call extend(mess, s:messages)
    call writefile(mess, 'vim-diction.log', '')
endfunction

function s:parse_db(db_name)
    " Parses a database.
    "
    " db_name: db_name can be one of the following:
    "   1. full or relative path
    "   2. name
    "   In case of a name the database is assumed to be shipped.
    " returns a dictionary or 0 if the database does not exist or is not
    "   readable

    let db_path = expand(a:db_name)
    if !filereadable(db_path)
        " The parameter does not point to a readable file, assuming
        " shipped database
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
    " Retrieves the name of the active set name (buflocal -> global ->
    " 'default') and then returns the set associated with that name.
    "
    " returns list of databases
    let setname = get(b:, 'diction_active_set',
                \ get(g:, 'diction_active_set', 'default')
                \ )

    return get(g:diction_db_sets, setname, [])
endfunction

function diction#set_active_set(set)
    " Sets the active set and reindexes.
    "
    " set: New active set.
    if index(keys(g:diction_db_sets), a:set) == -1
        call s:mess('error', 'Given set ' . a:set . ' not in defined sets')
        return
    endif
    let g:diction_active_set = a:set
    call diction#reindex()
endfunction

function diction#complete_db_sets(ArgLead, CmdLine, CursorPos)
    " Completion function. See :command-completion-customlist for
    " details
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
    " Reindexes the current set of databases
    let s:lookup = {}
    for db in s:get_active_set()
        call extend(s:lookup, s:parse_db(db))
    endfor
endfunction

function diction#check_buffer(filepath)
    " Checks given file for dictions. The file will be opened if it is
    " not loaded.
    "
    " filepath: Name or path for a file. If empty the current buffer is
    "   used. The name is globbed in &path.
    " returns a list of dictionaries with matches setqflist() would
    "   accept with filename set.

    " save current position
    let sav_pos = getcurpos()
    let sav_buf = bufnr('%')

    if empty(a:filepath)
        " use current buffer if filepath is empty
        let filepath = bufname('%')
    else
        " glob for file in &path, error if it doesn't exist
        let filepath = globpath(&path, a:filepath, 0, 1)
        if empty(filepath)
            call s:mess('error', 'Filepath ' . a:filepath . ' globbed to empty path')
            return
        endif
        let filepath = filepath[0]

        " save the current position and open file
        let bufnr = bufnr(filepath, 1)
        exec 'b ' . bufnr
    endif

    if empty(s:lookup)
        " fill lookup table if the databases weren't indexed yet
        call diction#reindex()
    endif

    " list of matches, each match is a dictionary, that setqflist()
    " would accept
    let matches = []

    for problem in keys(s:lookup)
        for matched in s:matchlist(problem)
            call add(matches, {
                        \ 'filename': filepath,
                        \ 'lnum': matched[0],
                        \ 'col': matched[1],
                        \ 'text': problem . ' -> ' . s:lookup[problem]
                        \ })
        endfor
    endfor

    exe 'b ' . sav_buf
    call setpos('.', sav_pos)
    return sort(matches, function('s:sort_matches'))
endfunction

function s:matchlist(pattern)
    " Searches the current buffer from top to bottom for a pattern. The
    " pattern will be modified.
    "
    " pattern: pattern to search
    " returns a list of matches, each match is a list [lnum, col]

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
    call s:mess('debug', 'Matching pattern "' . pattern . '" in file ' . bufname('%'))

    call setpos('.', [0, 1, 1, 0])
    "            |    |  |  |  +- offset
    "            |    |  |  +- first col
    "            |    |  +- first line
    "            |    +- current buffer
    "            +- set cursor

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
    return matches
endfunction

function s:sort_matches(a, b)
    " Sort function to sort setqflist()-compatible entries via sort()
    "
    " a, b: entries
    "
    " returns: 1 if a should be ordered later in the list, -1 for
    "   earlier, 0 for equal
    if a:a.filename > a:b.filename
        return 1
    elseif a:b.filename < a:b.filename
        return -1
    endif

    if 0 != a:a.lnum - a:b.lnum
        return a:a.lnum - a:b.lnum
    endif

    return a:a.col - a:b.col
endfunction

function diction#fill_list(qf, add)
    " Fills the quickfix or location list with entries from
    " check_buffer()
    "
    " qf: boolean, 1 if quickfix should be filled
    " add: boolean, 1 if the entries should be added
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
