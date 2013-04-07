" File:        xkbswitch.vim
" Authors:     Alexey Radkov
"              Dmitry Hrabrov a.k.a. DeXPeriX (softNO@SPAMdexp.in)
" Version:     0.3
" Description: Automatic keyboard layout switching upon entering/leaving
"              insert mode

scriptencoding utf-8

if exists('g:loaded_XkbSwitch') && g:loaded_XkbSwitch
    finish
endif

let g:loaded_XkbSwitch = 1

if !exists('g:XkbSwitchLib')
    if has('unix')
        let g:XkbSwitchLib = '/usr/local/lib/libxkbswitch.so'
    elseif has('win64')
        let g:XkbSwitchLib = 'libxkbswitch64.dll'
    elseif has('win32')
        let g:XkbSwitchLib = 'libxkbswitch32.dll'
    else
        " not supported yet
        finish
    endif
endif

let s:XkbSwitchDict = {
            \ 'unix':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'zero':    '',
            \  'default': 'us'},
            \ 'win32':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'zero':    '',
            \  'default': 'us'},
            \ 'win64':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'zero':    '',
            \  'default': 'us'},
            \ }

if !exists('g:XkbSwitch')
    if has('unix')
        let g:XkbSwitch = s:XkbSwitchDict['unix']
    elseif has('win32')
        let g:XkbSwitch = s:XkbSwitchDict['win32']
    elseif has('win64')
        let g:XkbSwitch = s:XkbSwitchDict['win64']
    else
        " not supported yet
        finish
    endif
endif

if !exists('g:XkbSwitchIMappings')
    let g:XkbSwitchIMappings = []
endif


fun! <SID>tr_escape_spec(data)
    return substitute(substitute(substitute(substitute(substitute(a:data,
                \ '\', '\\\\\\\\', 'g'), "\x22", '\\\\x22', 'g'),
                \ "\x27", '\\\\x27', 'g'), "\\$", '\\\\x24', 'g'),
                \ "\x26", '\\\\x26', 'g')
endfun

fun! <SID>tr_load(file)
    let g:XkbSwitchIMappingsTr = {}
    let tr = ''
    for line in readfile(a:file, '')
        if line =~ '\(^\s*#\|^\s*$\)'
            continue
        endif
        let data = split(line)
        if data[0] == '<' || data[0] == '>'
            if tr == ''
                continue
            endif
            if !exists('g:XkbSwitchIMappingsTr[tr]')
                let g:XkbSwitchIMappingsTr[tr] = {}
            endif
            let g:XkbSwitchIMappingsTr[tr][data[0]] =
                        \ <SID>tr_escape_spec(data[1])
        else
            let tr = data[0]
        endif
    endfor
endfun

fun! <SID>tr_load_default()
    let from = <SID>tr_escape_spec(
                \ 'qwertyuiop[]asdfghjkl;''zxcvbnm,.`/'.
                \ 'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|')
    let g:XkbSwitchIMappingsTr = {
                \ 'ru':
                \ {'<': from,
                \  '>': <SID>tr_escape_spec(
                \       'йцукенгшщзхъфывапролджэячсмитьбюё.'.
                \       'ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё"№;:?/')},
                \ }
endfun

fun! <SID>tr_escape_imappings()
    for key in keys(g:XkbSwitchIMappingsTr)
        if exists('g:XkbSwitchIMappingsTr[key]["<"]')
            let g:XkbSwitchIMappingsTr[key]['<'] =
                    \ <SID>tr_escape_spec(g:XkbSwitchIMappingsTr[key]['<'])
        endif
        if exists('g:XkbSwitchIMappingsTr[key][">"]')
            let g:XkbSwitchIMappingsTr[key]['>'] =
                    \ <SID>tr_escape_spec(g:XkbSwitchIMappingsTr[key]['>'])
        endif
    endfor
endfun

if !exists('g:XkbSwitchIMappingsTr')
    if exists('g:XkbSwitchIMappingsTrData') &&
                \ filereadable(g:XkbSwitchIMappingsTrData)
        call <SID>tr_load(g:XkbSwitchIMappingsTrData)
    else
        call <SID>tr_load_default()
    endif
else
    call <SID>tr_escape_imappings()
endif


fun! <SID>xkb_mappings_load()
    for hcmd in ['gh', 'gH', 'g']
        exe "nnoremap <buffer> <silent> ".hcmd.
                    \ " :call <SID>xkb_switch(1)<CR>".hcmd
    endfor
    xnoremap <buffer> <silent> <C-g> :<C-u>call <SID>xkb_switch(1)<CR>gv<C-g>
    snoremap <buffer> <silent> <C-g> <C-g>:<C-u>call <SID>xkb_switch(0)<CR>gv
    let b:xkb_mappings_loaded = 1
endfun

fun! <SID>imappings_load()
    if empty(g:XkbSwitchIMappings)
        return
    endif
    redir => mappingsdump
    silent imap
    redir END
    let mappings = split(mappingsdump, '\n')
    let mappingskeys = {}
    for mapping in mappings
        let mappingskeys[split(mapping)[1]] = 1
    endfor
    for tr in g:XkbSwitchIMappings
        if !exists('g:XkbSwitchIMappings[tr]')
            continue
        endif
        for mapping in mappings
            let value = substitute(mapping,
                        \ '\s*\S\+\s\+\S\+\s\+\(.*\)', '\1', '')
            " do not duplicate <script> mappings (when value contains '&')
            if match(value, '^[\s*@]*&') != -1
                continue
            endif
            let data = split(mapping)
            " do not duplicate <Plug> mappings (when key starts with '<Plug>')
            if match(data[1], '^\c<Plug>') != -1
                continue
            endif
            let from = g:XkbSwitchIMappingsTr[tr]['<']
            let to   = g:XkbSwitchIMappingsTr[tr]['>']
            " protect special symbols before next evaluations
            let newkey = substitute(substitute(substitute(substitute(
                        \ substitute(data[1], '\', '\\\\', 'g'),
                        \ "\x22", '\\\x22', 'g'), "\x27", '\\\x27', 'g'),
                        \ "\\$", '\\\x24', 'g'), "\x26", '\\\x26', 'g')
            " pre-evaluate the new key
            let newkey = substitute(newkey,
                        \ '\(\%(<[^>]\+>\)*\)\(.\{-}\)\(\%(<[^>]\+>\)*\)$',
                        \ '"\1".tr("\2", "'.from.'", "'.to.'")."\3"', 'i')
            " evaluate the new key
            let newkey = eval(newkey)
            " do not reload existing mapping unnecessarily
            if newkey == data[1] || exists('mappingskeys[newkey]')
                continue
            endif
            let mapcmd = match(value, '^[\s&@]*\*') == -1 ? 'imap' :
                        \ 'inoremap'
            " probably the mapping was defined using <expr>
            let expr = match(value,
                        \ '^[\s*&@]*[a-zA-Z][a-zA-z0-9_#\-]*(.\{-})$') != -1 ?
                        \ '<expr>' : ''
            " new maps are always silent and buffer-local
            exe mapcmd.' <silent> <buffer> '.expr.' '.newkey.' '.
                        \ maparg(data[1], 'i')
        endfor
    endfor
endfun

fun! <SID>xkb_switch(mode)
    let cur_layout = libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'],
                \ g:XkbSwitch['zero'])
    if a:mode == 0
        if cur_layout != g:XkbSwitch['default']
            call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                        \ g:XkbSwitch['default'])
        endif
        let b:xkb_layout = cur_layout
    elseif a:mode == 1
        if !exists('b:xkb_mappings_loaded')
            call <SID>xkb_mappings_load()
            call <SID>imappings_load()
        endif
        if exists('b:xkb_layout')
            if b:xkb_layout != cur_layout
                call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                            \ b:xkb_layout)
            endif
        endif
    endif
endfun

fun! <SID>enable_xkb_switch(force)
    if exists('g:XkbSwitchEnabled') && g:XkbSwitchEnabled && !a:force
        return
    endif
    if filereadable(g:XkbSwitch['backend']) == 1
        autocmd InsertEnter * call <SID>xkb_switch(1)
        autocmd InsertLeave * call <SID>xkb_switch(0)
    endif
    let g:XkbSwitchEnabled = 1
endfun


command EnableXkbSwitch call <SID>enable_xkb_switch(0)

if exists('g:XkbSwitchEnabled') && g:XkbSwitchEnabled
    call <SID>enable_xkb_switch(1)
endif

