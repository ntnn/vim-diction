" vim-diction
" Maintainer:	ntnn <nelo@wallus.de>
" Version:	1
" License:	MIT
" Website:	https://github.com/ntnn/vim-diction

let s:save_cpo = &cpo
set cpo&vim

function s:log(message)
    if get(g:, 'diction_debug', 0)
        " check if message is a list
        if type(a:message) == type([])
            call s:log('List logged:')
            for mess in a:message
                echomsg 'vim-diction:  ' . mess
            endfor
        else
            echomsg 'vim-diction:' . a:message
        endif
    endif
endfunction

function diction#writelog()
    redir => mess
        messages
    redir END
    let mess = split(mess, '\n')
    call writefile(mess, 'vim-diction.log', '')
endfunction

function diction#wrap(qf)
    " TODO: Allow ranges to pass those through to diction via stdin.
    "       In that case an offset has to be given to calculate_lnumcol
    " TODO: Allow different / multiple files
    let file = expand('%')
    call s:log('Started wrapper on "' . file . '" on qf:' . a:qf)

    let cmd = a:qf? 'cexpr ' : 'lexpr '
    let cmd .= 'diction#run(file)'
    exec cmd
endfu

function diction#run(file)
    let cmd = 'diction'

    if get(g:, 'diction_suggest', 1)
        let cmd .= ' --suggest '
    endif
    let cmd .= get(g:, 'diction_options', '')
    let cmd .= a:file

    call s:log('Command ' . cmd)

    let output = split(system(cmd), '\n')
    if empty(output)
        call s:log('No output')
        return
    endif

    call filter(output, '!empty(v:val)')
    call remove(output, -1)

    let parsed = []
    for line in output
        for parsed_line in s:parse_line(line)
            call add(parsed, parsed_line)
        endfor
    endfor

    return parsed
endfunction

function s:parse_line(line) abort
    call s:log('Parsing line ' . a:line)
    " split input line into filename, line/column numbers and sentence
    let lines = split(a:line, ':')
    let file = lines[0]
    if len(split(lines[1], '[\.\-]')) == 4
        let [start_lnum, start_col, end_lnum, end_col] = split(lines[1], '[\.\-]')
    else
        let [start_lnum, end_lnum] = split(lines[1], '[\.\-]')
        let [start_col, end_col] = [0, 0]
    endif
    let lines = lines[2]
    call s:log('File: ' . file)
    call s:log('Start line: ' . start_lnum . ' col: ' . start_col)
    call s:log('End line: ' . end_lnum . ' col: ' . end_col)
    call s:log('Parsing line ' . lines)

    " work through the sentence from annotation to annotation
    let cur_lnum = start_lnum
    let cur_col = start_col
    let ret = []
    while !empty(lines)
        let nextopen = match(lines, '[')
        let nextclose = match(lines, ']')
        if nextclose > nextopen
            " jump over non-matching brackets
            if nextopen == -1 || nextclose == -1
                " no [ or matching ] was found, returning ret
                break
            endif
            call s:log('Next open: ' . nextopen . ' close: ' . nextclose)

            let [cur_lnum, cur_col] = s:calculate_lnumcol(file, cur_lnum, cur_col, nextopen)
            let annotation = lines[nextopen + 1:nextclose - 1]
            call s:log(annotation)

            if get(g:, 'diction_formatter') != ''
                let output = split(system(g:diction_formatter, annotation), '\n')
            else
                let output = [annotation]
            endif
            call s:log(output)

            call add(ret, printf("%s:%d:%d:%s", file, cur_lnum, cur_col, output[0]))
            call remove(output, 0)
            for line in output
                call add(ret, line)
            endfor
        endif

        let lines = lines[nextclose + 2:]
        "                           +- cut off the ] and space that'd be left over
    endwhile

    return l:ret
endfunction

function s:calculate_lnumcol(file, lnum, col, delta)
    " TODO: For some reason the calculated lnum/col are a few characters
    "       off, sometimes positive, sometimes negative.
    let bufnr = bufnr(a:file)
    if bufnr == -1
        " load file as buffer if not present
        exec 'silent! e ' . file
        normal! <c-o>
        let bufnr = bufnr(a:file)
    endif

    let lnum = a:lnum
    let col = a:col
    let delta = a:delta

    while delta > 0
        let [line] = getbufline(bufnr, lnum)
        " TODO: Better way to remove leading and trailing whitespace
        let linelen = strchars(substitute(line, '  ', '', 'g'))
        call s:log('Linelen: ' . linelen . ' line: ' . line)

        if linelen > delta
            " delta is within the current line, search match and return
            break
        endif

        let delta = delta - linelen
        let lnum += 1
        call s:log('Line not sufficiently long, delta: ' . delta . ' on line ' . lnum)
    endwhile

    return [lnum, col + delta]
endfunction

let &cpo = s:save_cpo
