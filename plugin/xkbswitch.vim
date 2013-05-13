" File:        xkbswitch.vim
" Authors:     Alexey Radkov
"              Dmitry Hrabrov a.k.a. DeXPeriX (softNO@SPAMdexp.in)
" Version:     0.9.2
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

" 'local' defines if backend gets and sets keyboard layout locally in the
" window or not
let s:XkbSwitchDict = {
            \ 'unix':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'local':   0},
            \ 'win32':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'local':   1},
            \ 'win64':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'local':   1},
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

if !exists('g:XkbSwitchEnabled')
    let g:XkbSwitchEnabled = 0
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

if !exists('g:XkbSwitchSyntaxRules')
    let g:XkbSwitchSyntaxRules = []
endif

" gvim client-server workaround:
" 1. Globally managed keyboard layouts:
"    Save Insert mode keyboard layout periodically (as fast as CursorHoldI
"    event triggers). This is important as gvim can lose it if another file is
"    being open from an external program (terminal or file manager) using
"    option --remote-tab (and similar)
" 2. Per window managed keyboard layouts:
"    Save Insert mode keyboard layout in TabLeave event
let s:XkbSwitchSaveILayout = has('gui_running') && has('clientserver')
let s:XkbSwitchFocused = 1
let s:XkbSwitchLastIEnterBufnr = 0


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

fun! <SID>check_syntax_rules(force)
    let col = col('.') == col('$') ? col('.') - 1 : col('.')
    let cur_synid  = synIDattr(synID(line("."), col, 1), "name")
    if !exists('b:xkb_saved_cur_synid')
        let b:xkb_saved_cur_synid = cur_synid
    endif
    if !exists('b:xkb_saved_cur_layout')
        let b:xkb_saved_cur_layout = {}
    endif
    if cur_synid != b:xkb_saved_cur_synid || a:force
        let cur_layout = ''
        let switched = 0
        for role in b:xkb_syntax_in_roles
            if index(b:xkb_syntax_out_roles, role) != -1 && a:force
                continue
            endif
            if b:xkb_saved_cur_synid == role
                let cur_layout =
                    \ libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
                let b:xkb_saved_cur_layout[role] = cur_layout
                break
            endif
        endfor
        for role in b:xkb_syntax_in_roles
            if cur_synid == role
                if index(b:xkb_syntax_out_roles, b:xkb_saved_cur_synid) == -1
                    let cur_layout1 = cur_layout != '' ? cur_layout :
                                \ libcall(g:XkbSwitch['backend'],
                                \ g:XkbSwitch['get'], '')
                    let b:xkb_ilayout = cur_layout1
                endif
                if exists('b:xkb_saved_cur_layout[role]')
                    if b:xkb_saved_cur_layout[role] != cur_layout
                        call libcall(g:XkbSwitch['backend'],
                                    \ g:XkbSwitch['set'],
                                    \ b:xkb_saved_cur_layout[role])
                        let switched = 1
                    endif
                else
                    let b:xkb_saved_cur_layout[role] = empty(cur_layout) ?
                                \ libcall(g:XkbSwitch['backend'],
                                \ g:XkbSwitch['get'], '') : cur_layout
                endif
                break
            endif
        endfor
        if switched
            let b:xkb_saved_cur_synid = cur_synid
            return
        endif
        for role in b:xkb_syntax_out_roles
            if b:xkb_saved_cur_synid == role
                let ilayout = exists('b:xkb_ilayout') ? b:xkb_ilayout :
                            \ ( exists('g:XkbSwitchILayout') ?
                            \ g:XkbSwitchILayout : '' )
                if ilayout != ''
                    if ilayout != cur_layout
                        call libcall(g:XkbSwitch['backend'],
                                    \ g:XkbSwitch['set'], ilayout)
                    endif
                endif
                break
            endif
        endfor
        let b:xkb_saved_cur_synid = cur_synid
    endif
endfun

fun! <SID>syntax_rules_load()
    for rule in g:XkbSwitchSyntaxRules
        let in_roles = []
        let out_roles = []
        if exists('rule["in"]')
            let in_roles = rule['in']
        endif
        if exists('rule["inout"]')
            let out_roles = rule['inout']
            let in_roles += out_roles
        endif
        let in_quote = empty(in_roles) ? '' : "'"
        let out_quote = empty(out_roles) ? '' : "'"
        augroup XkbSwitch
            if exists('rule["pat"]')
                exe "autocmd InsertEnter ".rule['pat'].
                            \ " if !exists('b:xkb_syntax_in_roles') | ".
                            \ "let b:xkb_syntax_in_roles = [".in_quote.
                            \ join(in_roles, "','").in_quote.
                            \ "] | let b:xkb_syntax_out_roles = [".out_quote.
                            \ join(out_roles, "','").out_quote.
                            \ "] | endif | call <SID>check_syntax_rules(1)"
                exe "autocmd CursorMovedI ".rule['pat'].
                            \ " if !exists('b:xkb_syntax_in_roles') | ".
                            \ "let b:xkb_syntax_in_roles = [".in_quote.
                            \ join(in_roles, "','").in_quote.
                            \ "] | let b:xkb_syntax_out_roles = [".out_quote.
                            \ join(out_roles, "','").out_quote.
                            \ "] | endif | call <SID>check_syntax_rules(0)"
            endif
            if exists('rule["ft"]')
                exe "autocmd InsertEnter * if index(['".
                            \ join(split(rule['ft'], '\s*,\s*'), "','").
                            \ "'], &ft) != -1 | ".
                            \ "if !exists('b:xkb_syntax_in_roles') | ".
                            \ "let b:xkb_syntax_in_roles = [".in_quote.
                            \ join(in_roles, "','").in_quote.
                            \ "] | let b:xkb_syntax_out_roles = [".out_quote.
                            \ join(out_roles, "','").out_quote.
                            \ "] | endif | call <SID>check_syntax_rules(1) ".
                            \ "| endif"
                exe "autocmd CursorMovedI * if index(['".
                            \ join(split(rule['ft'], '\s*,\s*'), "','").
                            \ "'], &ft) != -1 | ".
                            \ "if !exists('b:xkb_syntax_in_roles') | ".
                            \ "let b:xkb_syntax_in_roles = [".in_quote.
                            \ join(in_roles, "','").in_quote.
                            \ "] | let b:xkb_syntax_out_roles = [".out_quote.
                            \ join(out_roles, "','").out_quote.
                            \ "] | endif | call <SID>check_syntax_rules(0) ".
                            \ "| endif"
            endif
        augroup END
    endfor
endfun

fun! <SID>save_ilayout(cur_layout)
    let ilayout_role = 'b:xkb_ilayout'
    if exists('b:xkb_syntax_out_roles')
        let col = col('.') == col('$') ? col('.') - 1 : col('.')
        let cur_synid  = synIDattr(synID(line("."), col, 1), "name")
        for role in b:xkb_syntax_out_roles
            if cur_synid == role
                if !exists('b:xkb_saved_cur_layout')
                    let b:xkb_saved_cur_layout = {}
                endif
                let ilayout_role = 'b:xkb_saved_cur_layout["'.role.'"]'
                break
            endif
        endfor
    endif
    exe "let ".ilayout_role." = '".a:cur_layout."'"
endfun

fun! <SID>xkb_switch(mode, ...)
    if s:XkbSwitchSaveILayout && !g:XkbSwitch['local'] && !s:XkbSwitchFocused
        return
    endif
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
            call <SID>save_ilayout(cur_layout)
        endif
    elseif a:mode == 1
        if !exists('b:xkb_mappings_loaded')
            call <SID>xkb_mappings_load()
            call <SID>imappings_load()
            call <SID>syntax_rules_load()
        endif
        let switched = 0
        if a:0 && a:1 && exists('b:xkb_syntax_in_roles')
            let col = mode() =~ '^[vV]' ? col('v') : col('.')
            let line = mode() =~ '^[vV]' ? line('v') : line('.')
            let cur_synid  = synIDattr(synID(line, col, 1), "name")
            for role in b:xkb_syntax_in_roles
                if cur_synid == role && exists('b:xkb_saved_cur_layout[role]')
                    if b:xkb_saved_cur_layout[role] != cur_layout
                        call libcall(g:XkbSwitch['backend'],
                                    \ g:XkbSwitch['set'],
                                    \ b:xkb_saved_cur_layout[role])
                        let switched = 1
                    endif
                    break
                endif
            endfor
        endif
        if !switched
            let ilayout = exists('b:xkb_ilayout') ? b:xkb_ilayout :
                \ ( exists('g:XkbSwitchILayout') ? g:XkbSwitchILayout : '' )
            if ilayout != ''
                if ilayout != cur_layout && !exists('b:xkb_ilayout_managed')
                    call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                                \ ilayout)
                endif
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
    let imode = mode() =~ '^[iR]'
    let save_ilayout_param = s:XkbSwitchSaveILayout && a:0
    if save_ilayout_param && !g:XkbSwitch['local'] &&
                \ ( !imode || !s:XkbSwitchFocused )
        return
    endif
    for ft in g:XkbSwitchSkipFt
        if ft == &ft
            return
        endif
    endfor
    let save_ilayout_param_local = save_ilayout_param && g:XkbSwitch['local']
    " BEWARE: if buffer has not entered Insert mode yet (i.e.
    " b:xkb_mappings_loaded is not loaded yet) then specific Normal mode
    " keyboard layout for this buffer will be lost
    let xkb_loaded = save_ilayout_param_local ?
                \ getbufvar(a:1, 'xkb_mappings_loaded') :
                \ exists('b:xkb_mappings_loaded')
    if !xkb_loaded
        return
    endif
    let cur_layout = libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
    if save_ilayout_param_local
        " FIXME: is there a way to find cursor position in the abandoned
        " buffer? If no then we cannot say what syntax role or 'xkb_layout'
        " must be restored and using syntax rules in this case can break
        " keyboard layouts when returning to the abandoned buffer
        call setbufvar(a:1, 'xkb_ilayout', cur_layout)
    else
        if imode
            call <SID>save_ilayout(cur_layout)
        else
            if g:XkbSwitchNLayout == ''
                let b:xkb_nlayout = cur_layout
            endif
        endif
    endif
endfun

fun! <SID>enable_xkb_switch(force)
    if g:XkbSwitchEnabled && !a:force
        return
    endif
    if filereadable(g:XkbSwitch['backend']) == 1
        augroup XkbSwitch
            au!
            autocmd InsertEnter *
                        \ let s:XkbSwitchLastIEnterBufnr = bufnr('%') |
                        \ call <SID>xkb_switch(1)
            for item in g:XkbSwitchPostIEnterAuto
                if exists('item[0]["pat"]')
                    exe "autocmd InsertEnter ".item[0]['pat']." ".
                                \ item[0]['cmd']." | if ".item[1].
                                \ " | let b:xkb_ilayout_managed = 1 | endif"
                endif
                if exists('item[0]["ft"]')
                    exe "autocmd InsertEnter * if &ft == '".item[0]['ft'].
                        \ "' | ".item[0]['cmd']." | if ".item[1].
                        \ " | let b:xkb_ilayout_managed = 1 | endif | endif"
                endif
            endfor
            autocmd InsertLeave * call <SID>xkb_switch(0)
            " BEWARE: Select modes are not supported well when navigating
            " between windows or tabs due to vim restrictions
            autocmd BufEnter * let s:XkbSwitchLastIEnterBufnr = 0 |
                        \ call <SID>xkb_switch(mode() =~ '^[iR]', 2)
            autocmd BufLeave * let s:XkbSwitchLastIEnterBufnr = 0 |
                        \ call <SID>xkb_save()
            if s:XkbSwitchSaveILayout
                if g:XkbSwitch['local']
                    autocmd TabLeave * if s:XkbSwitchLastIEnterBufnr != 0 &&
                        \ s:XkbSwitchLastIEnterBufnr != bufnr('%') |
                        \ call <SID>xkb_save(s:XkbSwitchLastIEnterBufnr) |
                        \ endif
                else
                    autocmd FocusGained * let s:XkbSwitchFocused = 1
                    autocmd FocusLost   * let s:XkbSwitchFocused = 0
                    autocmd CursorHoldI * call <SID>xkb_save(1)
                endif
            endif
        augroup END
    endif
    let g:XkbSwitchEnabled = 1
endfun


command EnableXkbSwitch call <SID>enable_xkb_switch(0)

if g:XkbSwitchEnabled
    call <SID>enable_xkb_switch(1)
endif

