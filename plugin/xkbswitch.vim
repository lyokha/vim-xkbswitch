" File:        xkbswitch.vim
" Authors:     Alexey Radkov
"              Dmitry Hrabrov a.k.a. DeXPeriX (softNO@SPAMdexp.in)
" Version:     0.8.1
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
        let g:XkbSwitchLib = $VIMRUNTIME.'/libxkbswitch64.dll'
    elseif has('win32')
        let g:XkbSwitchLib = $VIMRUNTIME.'/libxkbswitch32.dll'
    else
        " not supported yet
        finish
    endif
endif

let s:XkbSwitchDict = {
            \ 'unix':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout'},
            \ 'win32':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout'},
            \ 'win64':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout'},
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

if !exists('g:XkbSwitchSkipFt')
    let g:XkbSwitchSkipFt = [ 'tagbar', 'gundo', 'nerdtree', 'fuf' ]
endif

if !exists('g:XkbSwitchNLayout')
    let g:XkbSwitchNLayout = ''
endif

if !exists('g:XkbSwitchILayout')
    let g:XkbSwitchILayout = ''
endif


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
            let g:XkbSwitchIMappingsTr[tr][data[0]] = data[1]
        else
            let tr = data[0]
        endif
    endfor
endfun

fun! <SID>tr_load_default()
    let from = 'qwertyuiop[]asdfghjkl;''zxcvbnm,.`/'.
                \ 'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|'
    let g:XkbSwitchIMappingsTr = {
                \ 'ru':
                \ {'<': from,
                \  '>': 'йцукенгшщзхъфывапролджэячсмитьбюё.'.
                \       'ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё"№;:?/'},
                \ }
endfun

fun! <SID>tr_escape_imappings()
    for key in keys(g:XkbSwitchIMappingsTr)
        if exists('g:XkbSwitchIMappingsTr[key]["<"]')
            let g:XkbSwitchIMappingsTr[key]['<'] =
                        \ g:XkbSwitchIMappingsTr[key]['<']
        endif
        if exists('g:XkbSwitchIMappingsTr[key][">"]')
            let g:XkbSwitchIMappingsTr[key]['>'] =
                        \ g:XkbSwitchIMappingsTr[key]['>']
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

if !exists('g:XkbSwitchIMappingsTrCtrl')
    let g:XkbSwitchIMappingsTrCtrl = 0
endif

if !exists('g:XkbSwitchIMappingsSkipFt')
    let g:XkbSwitchIMappingsSkipFt = []
endif

if !exists('g:XkbSwitchPostIEnterAuto')
    let g:XkbSwitchPostIEnterAuto = []
endif

if !exists('g:XkbSwitchFixNoBufLeave')
    let g:XkbSwitchFixNoBufLeave = 1
endif

let s:last_ienter_bufnr = 0


fun! <SID>xkb_mappings_load()
    for hcmd in ['gh', 'gH', 'g']
        exe "nnoremap <buffer> <silent> ".hcmd.
                    \ " :call <SID>xkb_switch(1, 1)<CR>".hcmd
    endfor
    xnoremap <buffer> <silent> <C-g>
                \ :<C-u>call <SID>xkb_switch(1, 1)<CR>gv<C-g>
    snoremap <buffer> <silent> <C-g>
                \ <C-g>:<C-u>call <SID>xkb_switch(0)<CR>gv
    let b:xkb_mappings_loaded = 1
endfun

fun! <SID>imappings_load()
    if empty(g:XkbSwitchIMappings)
        return
    endif
    for ft in g:XkbSwitchIMappingsSkipFt
        if ft == &ft
            return
        endif
    endfor
    redir => mappingsdump
    silent imap
    redir END
    let mappings = split(mappingsdump, '\n')
    let mappingskeys = {}
    for mapping in mappings
        let mappingskeys[split(mapping)[1]] = 1
    endfor
    for tr in g:XkbSwitchIMappings
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
            let from  = g:XkbSwitchIMappingsTr[tr]['<']
            let to    = g:XkbSwitchIMappingsTr[tr]['>']
            " replace characters starting control sequences with spaces
            let clean = ''
            if g:XkbSwitchIMappingsTrCtrl
                let clean = substitute(data[1],
                \ '\(<[^>]\{-}\)\(-\=\)\([^->]\+\)>',
                \ '\=repeat(" ", strlen(submatch(1)) + strlen(submatch(2))) .
                \ (strlen(submatch(3)) == 1 ? submatch(3) :
                \ repeat(" ", strlen(submatch(3)))) . " "', 'g')
            else
                let clean = substitute(data[1],
                \ '<[^>]\+>', '\=repeat(" ", strlen(submatch(0)))', 'g')
            endif
            " apply translations
            let newkey = tr(clean, from, to)
            " restore control characters from original mapping
            for i in range(strlen(substitute(clean, ".", "x", "g")))
                " BEWARE: in principle strlen(clean(...)) and strlen(data[1])
                " may differ in case if wide characters have been replaced by
                " spaces, however it should not happen as soon as wide
                " characters cannot start control character sequences
                if clean[i] == " "
                    exe
                    \ "let newkey = substitute(newkey, '\\(^[^ ]*\\) ', '\\1".
                    \ data[1][i]."', '')"
                endif
            endfor
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

fun! <SID>xkb_switch(mode,...)
    for ft in g:XkbSwitchSkipFt
        if ft == &ft
            return
        endif
    endfor
    let cur_layout = libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
    let nlayout = g:XkbSwitchNLayout != '' ? g:XkbSwitchNLayout :
                \ ( exists('b:xkb_nlayout') ? b:xkb_nlayout : '' )
    if a:mode == 0
        if nlayout != ''
            if cur_layout != nlayout
                call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                            \ nlayout)
            endif
        endif
        if !a:0 || a:1 != 2
            let b:xkb_ilayout = cur_layout
        endif
    elseif a:mode == 1
        if !exists('b:xkb_mappings_loaded')
            call <SID>xkb_mappings_load()
            call <SID>imappings_load()
        endif
        let ilayout = exists('b:xkb_ilayout') ? b:xkb_ilayout :
                \ ( exists('g:XkbSwitchILayout') ? g:XkbSwitchILayout : '' )
        if ilayout != ''
            if ilayout != cur_layout && !exists('b:xkb_ilayout_managed')
                call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                            \ ilayout)
            endif
        endif
        if !exists('b:xkb_pending_imode')
            let b:xkb_pending_imode = 0
        endif
        if g:XkbSwitchNLayout == ''
            if !b:xkb_pending_imode && (!a:0 || a:1 != 2)
                let b:xkb_nlayout = cur_layout
            endif
        endif
        let b:xkb_pending_imode = a:0 && a:1 == 1
    endif
endfun

fun! <SID>xkb_save(...)
    for ft in g:XkbSwitchSkipFt
        if ft == &ft
            return
        endif
    endfor
    " BEWARE: if buffer has not entered Insert mode yet (i.e.
    " b:xkb_mappings_loaded is not loaded yet) then specific Normal mode
    " keyboard layout for this buffer will be lost
    if !exists('b:xkb_mappings_loaded')
        return
    endif
    let cur_layout = libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
    if g:XkbSwitchFixNoBufLeave && exists('a:1')
        call setbufvar(a:1, 'xkb_ilayout', cur_layout)
    else
        if mode() =~ '^[iR]'
            let b:xkb_ilayout = cur_layout
        else
            if g:XkbSwitchNLayout == ''
                let b:xkb_nlayout = cur_layout
            endif
        endif
    endif
endfun

fun! <SID>enable_xkb_switch(force)
    if exists('g:XkbSwitchEnabled') && g:XkbSwitchEnabled && !a:force
        return
    endif
    if filereadable(g:XkbSwitch['backend']) == 1
        augroup XkbSwitch
            au!
            autocmd InsertEnter * let s:last_ienter_bufnr = bufnr('%') |
                        \ call <SID>xkb_switch(1)
            for item in g:XkbSwitchPostIEnterAuto
                exe "autocmd InsertEnter ".item[0]['pat']." ".item[0]['cmd'].
                            \ " | if ".item[1].
                                \ " | let b:xkb_ilayout_managed = 1 | endif"
            endfor
            autocmd InsertLeave * call <SID>xkb_switch(0)
            " BEWARE: Select modes are not supported well when navigating
            " between windows or tabs due to vim restrictions
            autocmd BufEnter * let s:last_ienter_bufnr = 0 |
                        \ call <SID>xkb_switch(mode() =~ '^[iR]', 2)
            autocmd BufLeave * let s:last_ienter_bufnr = 0 |
                        \ call <SID>xkb_save()
            if g:XkbSwitchFixNoBufLeave
                autocmd TabLeave * if s:last_ienter_bufnr != 0 &&
                            \ s:last_ienter_bufnr != bufnr('%') |
                            \ call <SID>xkb_save(s:last_ienter_bufnr) | endif
            endif
        augroup END
    endif
    let g:XkbSwitchEnabled = 1
endfun


command EnableXkbSwitch call <SID>enable_xkb_switch(0)

if exists('g:XkbSwitchEnabled') && g:XkbSwitchEnabled
    call <SID>enable_xkb_switch(1)
endif

