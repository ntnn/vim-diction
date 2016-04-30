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
let s:test_functions = []

function s:mess(level, message)
    " Logger function.
    "
    " level: log level, either 'debug' or 'error'. Other is printed
    "   verbatim
    " message: Message to print. String or list.

    let prefix = 'vim-diction:' . expand('<sfile>') . ':'

    if type(a:message) == type([])
        for mess in a:message
            call s:mess(a:level, '  ' . mess)
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

call add(s:test_functions, 'write_log_to_file')
function diction#write_log_to_file()
    " Write messages to 'vim-diction.log'
    let mess = [
                \ 'Databases: ' . join(get(g:, 'diction_databases', [])),
                \ 'Dictions: ' . len(keys(s:lookup)),
                \ ]
    call extend(mess, s:messages)
    call writefile(mess, 'vim-diction.log', '')
endfunction

function s:write_log_to_file_test()
    call diction#write_log_to_file()
    call assert_true(filereadable('vim-diction.log'), 'Log file not created or not readable.')
endfunction

call add(s:test_functions, 'parse_db')
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

function s:parse_db_test()
    call assert_equal(
                \ { 'entry with': 'annotation',
                \   'entry without': 'Bad diction' },
                \ s:parse_db('test'),
                \ 'Parsed test database does not match expectation')

    call assert_equal(0,
                \ s:parse_db('non-existing-db'),
                \ 'Non existing database was accepted')
endfunction

call add(s:test_functions, 'get_active_set')
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

function s:get_active_set_test()
    silent! unlet g:diction_active_set
    silent! unlet b:diction_active_set
    call assert_equal(['en', 'en-tech_words_to_avoid'],
                \ s:get_active_set(),
                \ 'Returned active set is not the default when l: and g: are unlet')

    let g:diction_active_set = 'set_test'
    let g:diction_db_sets = { 'set_test': [ 'test_db' ] }
    call assert_equal([ 'test_db' ],
                \ s:get_active_set(),
                \ 'Returned active set does not match test set when l: is unlet and g: is let')

    let b:diction_active_set = 'local_set'
    let g:diction_db_sets = { 'local_set': [ 'local_test_db' ] }
    call assert_equal([ 'local_test_db' ],
                \ s:get_active_set(),
                \ 'Returned active set does not match test set when l: and g: are let')
endfunction

call add(s:test_functions, 'set_active_set')
function diction#set_active_set(set) abort
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

function s:set_active_set_test()
    let g:diction_db_sets = { 'test': ['test_db', 'test_db2'] }
    call diction#set_active_set('test')
    call assert_equal('test',
                \ g:diction_active_set,
                \ 'Setting of active set to test set failed')
    call assert_equal('test', g:diction_active_set, 'Active set not equal to test set')

    call assert_equal(0,
                \ diction#set_active_set('does_not_exist'),
                \ 'Setting of active set to non existent set succeeded')
    call assert_notequal('does_not_exist', g:diction_active_set, 'Active set set to non existant set')
endfunction

call add(s:test_functions, 'complete_db_sets')
function diction#complete_db_sets(ArgLead, CmdLine, CursorPos)
    " Completion function. See :command-completion-customlist for
    " details
    let completions = []

    for name in keys(g:diction_db_sets)
        if name =~ a:ArgLead
            call add(completions, name)
        endif
    endfor

    return completions
endfunction

function s:complete_db_sets_test()
    let g:diction_db_sets = {
                \ 'first': [],
                \ 'second': []
                \ }

    call assert_equal(['first'],
                \ diction#complete_db_sets('fi', 'DictionSet fi', 0),
                \ 'Returned wrong completion to ["first", "second"] with ArgLead "fi"')

    call assert_equal(['first', 'second'],
                \ diction#complete_db_sets('', 'DictionSet first ', 0),
                \ 'Returned non-empty list of completions upon finished completion')
endfunction

call add(s:test_functions, 'reindex')
function diction#reindex()
    " Reindexes the current set of databases
    let s:lookup = {}
    for db in s:get_active_set()
        call extend(s:lookup, s:parse_db(db))
    endfor
endfunction

function s:reindex_test()
    silent! unlet g:diction_active_set
    silent! unlet b:diction_active_set
    let g:diction_db_sets = {'default': []}

    call diction#reindex()
    call assert_equal({}, s:lookup, 'Parsed lookup not empty')

    let g:diction_db_sets = {'test': ['test']}
    let g:diction_active_set = 'test'
    call diction#reindex()
    call assert_equal({ 'entry with': 'annotation',
                \ 'entry without': 'Bad diction' },
                \ s:lookup,
                \ 'Reindexed table not equal to test database')
endfunction

call add(s:test_functions, 'check_buffer')
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

function s:check_buffer_test()
    let g:diction_db_sets = {'test': ['test']}
    let g:diction_active_set = 'test'
    let test_file = s:plugin_path . '/files/test.txt'
    call assert_true(filereadable(test_file), 'File with test text not readable or does not exist')

    call assert_equal([{
                \       'filename': test_file,
                \       'lnum': 3,
                \       'col': 12,
                \       'text': 'entry with -> annotation'
                \ },
                \ {
                \       'filename': test_file,
                \       'lnum': 1,
                \       'col': 23,
                \       'text': 'entry without -> Bad diction'
                \ }],
                \ diction#check_buffer(test_file),
                \ )

    call assert_equal(0,
                \ diction#check_buffer('random_non_existant_file.tlsl'),
                \ 'Non existant file checked')
endfunction

call add(s:test_functions, 'matchlist')
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

call add(s:test_functions, 'sort_matches')
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

call add(s:test_functions, 'fill_list')
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

function diction#test(...)
    for testee in s:test_functions
        let tester = 's:' . testee . '_test'
        try
            let Func = function(tester)
            silent! call Func()
        catch /E700/
            " Function does not exist
            call add(v:errors, 'Function ' . testee . ' is not covered')
            continue
        endtry
    endfor

    if empty(v:errors)
        echomsg 'Tests passed'
    else
        echomsg 'The following errors occured:'
        for error in v:errors
            echomsg error
        endfor

        if !empty(a:000)
            " intended for travis build, quits with errno on detected
            " errors
            cquit
        endif
    endif
endfunction

let &cpo = s:save_cpo
