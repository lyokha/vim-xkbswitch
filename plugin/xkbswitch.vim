" File:        xkbswitch.vim
" Authors:     Alexey Radkov
"              Dmitry Hrabrov a.k.a. DeXPeriX (softNO@SPAMdexp.in)
" Version:     0.16
" Description: Automatic keyboard layout switching upon entering/leaving
"              insert mode

scriptencoding utf-8

if exists('g:loaded_XkbSwitch') && g:loaded_XkbSwitch
    finish
endif

let g:loaded_XkbSwitch = 1

" prevent crashes of Vim due to xkb-switch (Github PR #30)
" FIXME: this is too strict because another hypothetical keyboard layout
"        switcher (that won't crash) can be used here
if !has('macunix') && has('unix') && empty($DISPLAY)
    let g:XkbSwitchEnabled = 0
endif

if !exists('g:XkbSwitchLib') && $XDG_SESSION_DESKTOP ==# 'gnome'
    if filereadable('/usr/local/lib/libg3kbswitch.so')
        let g:XkbSwitchLib = '/usr/local/lib/libg3kbswitch.so'
    elseif filereadable('/usr/lib/libg3kbswitch.so')
        let g:XkbSwitchLib = '/usr/lib/libg3kbswitch.so'
    endif
endif

if !exists('g:XkbSwitchLib')
    if has('macunix')
        if filereadable('/usr/local/lib/libxkbswitch.dylib')
            let g:XkbSwitchLib = '/usr/local/lib/libxkbswitch.dylib'
        elseif filereadable('/usr/lib/libxkbswitch.dylib')
            let g:XkbSwitchLib = '/usr/lib/libxkbswitch.dylib'
        endif
    elseif has('unix')
        " do not load if there is no X11,
        " see also comment about excessive strictness above
        if empty($DISPLAY)
            finish
        endif
        if filereadable('/usr/local/lib/libxkbswitch.so')
            let g:XkbSwitchLib = '/usr/local/lib/libxkbswitch.so'
        elseif filereadable('/usr/lib/libxkbswitch.so')
            let g:XkbSwitchLib = '/usr/lib/libxkbswitch.so'
        elseif filereadable('/usr/lib64/libxkbswitch.so')
            let g:XkbSwitchLib = '/usr/lib64/libxkbswitch.so'
        elseif filereadable('/usr/lib32/libxkbswitch.so')
            let g:XkbSwitchLib = '/usr/lib32/libxkbswitch.so'
        endif
    elseif has('win64') && filereadable($VIMRUNTIME.'/libxkbswitch64.dll')
        let g:XkbSwitchLib = $VIMRUNTIME.'/libxkbswitch64.dll'
    elseif has('win32') && filereadable($VIMRUNTIME.'/libxkbswitch32.dll')
        let g:XkbSwitchLib = $VIMRUNTIME.'/libxkbswitch32.dll'
    endif
endif

if !exists('g:XkbSwitchLib')
    echohl WarningMsg
    echo 'Please Install XkbSwitchLib!'
    echohl None
    finish
endif

" 'local' defines if backend gets and sets keyboard layout locally in the
" window or not
let s:XkbSwitchDict = {
            \ 'macunix':
            \ {'backend': g:XkbSwitchLib,
            \  'get':     'Xkb_Switch_getXkbLayout',
            \  'set':     'Xkb_Switch_setXkbLayout',
            \  'local':   0},
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
    if has('macunix')
        let g:XkbSwitch = s:XkbSwitchDict['macunix']
    elseif has('unix')
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

if !exists('g:XkbSwitchSkipIMappings')
    let g:XkbSwitchSkipIMappings = {}
endif

if !exists('g:XkbSwitchLoadRIMappings')
    let g:XkbSwitchLoadRIMappings = 1
endif

if !exists('g:XkbSwitchAssistNKeymap')
    let g:XkbSwitchAssistNKeymap = 0
endif

if !exists('g:XkbSwitchAssistSKeymap')
    let g:XkbSwitchAssistSKeymap = 0
endif

if !exists('g:XkbSwitchKeymapNames')
    let g:XkbSwitchKeymapNames = {}
endif

if !exists('g:XkbSwitchDynamicKeymap')
    let g:XkbSwitchDynamicKeymap = 0
endif

if !exists('g:XkbSwitchIminsertToggleKey')
    let g:XkbSwitchIminsertToggleKey = ''
endif

if !exists('g:XkbSwitchIminsertToggleEcho')
    let g:XkbSwitchIminsertToggleEcho = 1
endif

if !exists('g:XkbSwitchSkipFt')
    let g:XkbSwitchSkipFt = ['tagbar', 'gundo', 'nerdtree', 'fuf']
endif

" this was used to disable interference with float windows from plugin Coc,
" now that we skip 'nofile' buftypes, this seems obsolete
if !exists('g:XkbSwitchSkipWinVar')
    let g:XkbSwitchSkipWinVar = ['float']
endif

if !exists('g:XkbSwitchNLayout')
    let g:XkbSwitchNLayout = ''
endif

if !exists('g:XkbSwitchILayout')
    let g:XkbSwitchILayout = ''
endif

let s:XkbSwitchGlobalLayout = ''

if !exists('g:XkbSwitchRestoreGlobalLayout')
    let g:XkbSwitchRestoreGlobalLayout = 0
endif

if !exists('g:XkbSwitchEnabled')
    let g:XkbSwitchEnabled = 0
endif

if !exists('g:XkbSwitchLoadOnBufRead')
    let g:XkbSwitchLoadOnBufRead = 1
endif


fun! <SID>tr_load(file)
    let g:XkbSwitchIMappingsTr = {}
    let tr = ''
    for line in readfile(a:file, '')
        if line =~ '\(^\s*#\|^\s*$\)'
            continue
        endif
        let data = split(line)
        if empty(data)
            continue
        endif
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
                \ 'uk':
                \ {'<': from,
                \  '>': 'йцукенгшщзхЇфівапролджєячсмитьбю''.'.
                \       'ЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮ,ʼ"№;:?/'},
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

if !exists('g:XkbSwitchSkipGhKeys')
    let g:XkbSwitchSkipGhKeys = []
endif

if !exists('g:XkbSwitchSelectmodeKeys')
    let g:XkbSwitchSelectmodeKeys =
                \ ['<S-Left>', '<S-Right>', '<S-Up>', '<S-Down>', '<S-End>',
                \  '<S-Home>', '<S-PageUp>', '<S-PageDown>', '<S-C-Left>',
                \  '<S-C-Right>', '<S-C-Up>', '<S-C-Down>', '<S-C-End>',
                \  '<S-C-Home>', '<S-C-PageUp>', '<S-C-PageDown>']
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

let s:XkbSwitchIRegList = []
if g:XkbSwitchLoadRIMappings
    let s:XkbSwitchIRegList = range(char2nr('a'), char2nr('z'))
    for char in ['"', '%', '#', '*', '+', '/', ':', '.', '-', '=']
        call add(s:XkbSwitchIRegList, char2nr(char))
    endfor
endif


fun! <SID>skip_buf_or_win()
    if getbufvar('', '&buftype') == 'nofile' ||
                \ index(g:XkbSwitchSkipFt, &ft) != -1
        return 1
    endif
    for winvar in g:XkbSwitchSkipWinVar
        if getwinvar(0, winvar, 0)
            return 1
        endif
    endfor
    return 0
endfun


fun! <SID>load_all()
    if <SID>skip_buf_or_win()
        return
    endif
    if !exists('b:xkb_mappings_loaded')
        call <SID>xkb_mappings_load()
        call <SID>imappings_load()
        call <SID>syntax_rules_load()
    endif
endfun


fun! <SID>xkb_mappings_load()
    for hcmd in ['gh', 'gH', 'g']
        if index(g:XkbSwitchSkipGhKeys, hcmd) == -1
            exe "nnoremap <buffer> <silent> ".hcmd.
                        \ " :call <SID>xkb_switch(1, 1)<CR>".hcmd
        endif
    endfor
    xnoremap <buffer> <silent> <C-g>
                \ :<C-u>call <SID>xkb_switch(1, 1)<Bar>normal gv<CR><C-g>
    snoremap <buffer> <silent> <C-g>
                \ <C-g>:<C-u>call <SID>xkb_switch(0)<Bar>normal gv<CR>
    if &selectmode =~ 'mouse'
        snoremap <buffer> <silent> <LeftRelease>
            \ <C-g>:<C-u>call <SID>xkb_switch(1, 1)<Bar>normal gv<CR><C-g>
        nnoremap <buffer> <silent> <2-LeftMouse>
            \ viw:<C-u>call <SID>xkb_switch(1, 1)<Bar>normal gv<CR><C-g>
        nnoremap <buffer> <silent> <3-LeftMouse>
            \ V:<C-u>call <SID>xkb_switch(1, 1)<Bar>normal gv<CR><C-g>
        inoremap <buffer> <silent> <2-LeftMouse>
            \ <C-o>viw:<C-u>call <SID>xkb_switch(1, 1)<Bar>normal gv<CR><C-g>
        inoremap <buffer> <silent> <3-LeftMouse>
            \ <C-o>V:<C-u>call <SID>xkb_switch(1, 1)<Bar>normal gv<CR><C-g>
    endif
    if &selectmode =~ 'key' && &keymodel =~ 'startsel'
        for skey in g:XkbSwitchSelectmodeKeys
            exe "nnoremap <buffer> <silent> ".skey.
                        \ " :call <SID>xkb_switch(1, 1)<CR>".skey
            " BEWARE: there are at least 4 transitions from/to Insert mode:
            " 1. <C-o> triggers InsertLeave, looks like there is no way to
            "    skip this,
            " 2. <CR> triggers InsertEnter, this will restore Insert mode
            "    layout,
            " 3. <S-key> at the end of the mapping triggers InsertLeave that
            "    we skip using variable b:xkb_skip_skey (phase 1),
            " 4. When user start typing it triggers InsertEnter which is also
            "    skipped by b:xkb_skip_skey (phase 2).
            " Unfortunately transitions 1 and 2 cannot be skipped and may lead
            " to fast double keyboard layout switching that user may notice in
            " a system tray area.
            exe "inoremap <buffer> <silent> ".skey.
                        \ " <C-o>:let b:xkb_skip_skey = 1<CR>".skey
        endfor
    endif
    if &selectmode =~ 'cmd'
        for cmd in ['v', 'V', '<C-v>']
            exe "nnoremap <buffer> <silent> ".cmd.
                        \ " :call <SID>xkb_switch(1, 1)<CR>".cmd
        endfor
    endif
    if !empty(g:XkbSwitchIminsertToggleKey)
        exe "nnoremap <buffer> <silent> ".g:XkbSwitchIminsertToggleKey.
                    \ " :if !empty(&keymap) <Bar> if &iminsert == 0 <Bar>".
                    \ "setlocal iminsert=1 <Bar>".
                    \ "if g:XkbSwitchIminsertToggleEcho <Bar>".
                    \ "echo 'set keymap' &keymap <Bar> endif <Bar>".
                    \ "elseif &iminsert == 1 <Bar>".
                    \ "setlocal iminsert=0 <Bar>".
                    \ "if g:XkbSwitchIminsertToggleEcho <Bar>".
                    \ "echo 'unset keymap' &keymap <Bar> endif <Bar>".
                    \ "endif <Bar> endif<CR>"
    endif
    let b:xkb_mappings_loaded = 1
endfun

fun! <SID>imappings_load()
    if empty(g:XkbSwitchIMappings)
        return
    endif
    if index(g:XkbSwitchIMappingsSkipFt, &ft) != -1
        return
    endif
    let mappingsdump = ''
    if exists('*execute')
        let mappingsdump = execute('imap', 'silent!')
    else
        redir => mappingsdump
        silent imap
        redir END
    endif
    let mappings = split(mappingsdump, '\n')
    let mappingskeys = {}
    for mapping in mappings
        let data = split(mapping)
        if len(data) < 3 || data[0] != 'i' && data[0] != '!'
            continue
        endif
        let mappingskeys[data[1]] = 1
    endfor
    let skip_rim_list = []
    for tr in g:XkbSwitchIMappings
        let from = g:XkbSwitchIMappingsTr[tr]['<']
        let to   = g:XkbSwitchIMappingsTr[tr]['>']
        for mapping in mappings
            " FIXME: checking for basic mappings validity could be moved
            " outside the 'for tr' loop to avoid duplicate tests
            let data = split(mapping)
            if len(data) < 3 || data[0] != 'i' && data[0] != '!'
                continue
            endif
            let mapvalue = maparg(data[1], 'i')
            if empty(mapvalue)
                continue
            endif
            let value = substitute(mapping,
                        \ '\s*\S\+\s\+\S\+\s\+\(.*\)', '\1', '')
            " do not duplicate <script> mappings (when value contains '&')
            if match(value, '^[[:blank:]*@]*&') != -1
                continue
            endif
            " do not duplicate <Plug> and <SNR> mappings
            " (when key starts with '<Plug>' or '<SNR>')
            if match(data[1], '^\c<\%(Plug\|SNR\)>') != -1
                continue
            endif
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
                    exe "let newkey = substitute(newkey, '\\(^[^ ]*\\) ', ".
                                \ "\"\\\\1".escape(data[1][i], '"')."\", '')"
                endif
            endfor
            if g:XkbSwitchLoadRIMappings
                let rim_key = matchstr(data[1], '^\c<C-R>\zs.$')
                if !empty(rim_key)
                    if index(s:XkbSwitchIRegList, char2nr(rim_key)) == -1
                        let rim_key_tr = tr(rim_key, to, from)
                        if rim_key_tr != rim_key &&
                                    \ index(s:XkbSwitchIRegList,
                                    \ char2nr(rim_key_tr)) != -1
                            call add(skip_rim_list, rim_key_tr)
                        endif
                    else
                        call add(skip_rim_list, rim_key)
                    endif
                endif
            endif
            " do not reload existing mapping unnecessarily
            " FIXME: list of mappings to skip depends on value of &filetype,
            " therefore it must be reloaded on FileType events!
            if newkey == data[1] || exists('mappingskeys[newkey]') ||
                    \ (exists('g:XkbSwitchSkipIMappings[&ft]') &&
                    \ index(g:XkbSwitchSkipIMappings[&ft], data[1]) != -1) ||
                    \ (exists('g:XkbSwitchSkipIMappings["*"]') &&
                    \ index(g:XkbSwitchSkipIMappings["*"], data[1]) != -1)
                continue
            endif
            let mapcmd = match(value, '^[[:blank:]&@]*\*') == -1 ? 'imap' :
                        \ 'inoremap'
            " probably the mapping was defined using <expr>
            let expr = match(value,
                    \ '^[[:blank:]*&@]*[a-zA-Z][a-zA-Z0-9_#]*(.*)$') != -1 ?
                    \ '<expr>' : ''
            " new maps are always silent and buffer-local
            exe mapcmd.' <silent> <buffer> '.expr.' '.
                        \ substitute(newkey.' '.mapvalue, '|', '|', 'g')
        endfor
        if g:XkbSwitchLoadRIMappings
            for rim_key_nr in s:XkbSwitchIRegList
                let rim_key = nr2char(rim_key_nr)
                let rim_key_tr = tr(rim_key, from, to)
                if index(s:XkbSwitchIRegList, char2nr(rim_key_tr)) != -1 ||
                            \ index(skip_rim_list, rim_key) != -1
                    continue
                endif
                exe 'inoremap <silent> <buffer> <C-R>'.rim_key_tr.' <C-R>'.
                            \ rim_key
            endfor
        endif
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
    if cur_synid == b:xkb_saved_cur_synid && !a:force
        return
    endif
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
                if cur_layout == ''
                    let cur_layout =
                    \ libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
                endif
                let b:xkb_ilayout = cur_layout
            endif
            if exists('b:xkb_saved_cur_layout[role]')
                if b:xkb_saved_cur_layout[role] != cur_layout
                    call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                                \ b:xkb_saved_cur_layout[role])
                    let switched = 1
                endif
            else
                if cur_layout == ''
                    let cur_layout =
                    \ libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
                endif
                let b:xkb_saved_cur_layout[role] = cur_layout
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
                        \ g:XkbSwitchILayout
            if ilayout != '' && ilayout != cur_layout
                call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                            \ ilayout)
            endif
            break
        endif
    endfor
    let b:xkb_saved_cur_synid = cur_synid
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
    if <SID>skip_buf_or_win()
        return
    endif
    if s:XkbSwitchSaveILayout && !g:XkbSwitch['local'] && !s:XkbSwitchFocused
        return
    endif
    let cur_layout = libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
    if g:XkbSwitchRestoreGlobalLayout && empty(s:XkbSwitchGlobalLayout)
        let s:XkbSwitchGlobalLayout = cur_layout
    endif
    if a:mode == 0
        if exists('b:xkb_skip_skey') && b:xkb_skip_skey > 0
            let b:xkb_skip_skey = 2
            return
        endif
        let nlayout = g:XkbSwitchNLayout != '' ? g:XkbSwitchNLayout :
                    \ (exists('b:xkb_nlayout') ? b:xkb_nlayout : '')
        if nlayout != ''
            if cur_layout != nlayout
                call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                            \ nlayout)
            endif
        endif
        if g:XkbSwitchAssistNKeymap || g:XkbSwitchAssistSKeymap
            let keymap_switch = 0
            let skip_keymap_switch = 0
            let ilayout = a:0 && a:1 == 2 ?
                        \ (exists('b:xkb_ilayout') ?
                        \ b:xkb_ilayout : cur_layout) : cur_layout
            if g:XkbSwitchDynamicKeymap
                if exists('g:XkbSwitchKeymapNames[ilayout]')
                    if g:XkbSwitchKeymapNames[ilayout] == &keymap
                        let keymap_switch = 1
                    else
                        let save_iminsert = &iminsert
                        let save_imsearch = &imsearch
                        exe "setlocal keymap=".
                                    \ g:XkbSwitchKeymapNames[ilayout]
                        if !g:XkbSwitchAssistNKeymap
                            exe "setlocal iminsert=".save_iminsert
                        endif
                        if !g:XkbSwitchAssistSKeymap
                            let new_imsearch = save_imsearch == -1 ?
                                        \ save_iminsert : save_imsearch
                            exe "setlocal imsearch=".new_imsearch
                        endif
                        let skip_keymap_switch = 1
                    endif
                endif
            else
                let keymap_switch = exists('b:keymap_name') ?
                            \ (exists('g:XkbSwitchKeymapNames[ilayout]') ?
                            \  (g:XkbSwitchKeymapNames[ilayout] ==
                            \   b:keymap_name) :
                            \  ilayout == b:keymap_name) : 0
            endif
            if !skip_keymap_switch
                if g:XkbSwitchAssistNKeymap
                    exe "setlocal iminsert=".keymap_switch
                endif
                if g:XkbSwitchAssistSKeymap
                    exe "setlocal imsearch=".keymap_switch
                endif
            endif
        endif
        if !a:0 || a:1 != 2
            call <SID>save_ilayout(cur_layout)
        endif
        let b:xkb_pending_imode = 0
    elseif a:mode == 1
        if exists('b:xkb_skip_skey') && b:xkb_skip_skey > 1
            let b:xkb_skip_skey = 0
            return
        endif
        if !a:0 || a:1 != 2 || mode() =~ '^[iR]'
            if g:XkbSwitchAssistNKeymap
                setlocal iminsert=0
            endif
            if g:XkbSwitchAssistSKeymap
                setlocal imsearch=0
            endif
        endif
        call <SID>load_all()
        let switched = ''
        if a:0 && a:1 && exists('b:xkb_syntax_in_roles')
            let col = mode() =~ '^[vV]' ? col('v') : col('.')
            let line = mode() =~ '^[vV]' ? line('v') : line('.')
            let cur_synid  = synIDattr(synID(line, col, 1), "name")
            for role in b:xkb_syntax_in_roles
                if cur_synid == role && exists('b:xkb_saved_cur_layout[role]')
                    if b:xkb_saved_cur_layout[role] != cur_layout
                        let switched = b:xkb_saved_cur_layout[role]
                        call libcall(g:XkbSwitch['backend'],
                                    \ g:XkbSwitch['set'], switched)
                    endif
                    break
                endif
            endfor
        endif
        if !exists('b:xkb_pending_imode')
            let b:xkb_pending_imode = 0
        endif
        if switched == ''
            if b:xkb_pending_imode && b:xkb_pending_ilayout != cur_layout
                let b:xkb_ilayout = cur_layout
            else
                if !exists('b:XkbSwitchILayout') || b:XkbSwitchILayout != ''
                    let switched = exists('b:XkbSwitchILayout') ?
                            \ b:XkbSwitchILayout : (exists('b:xkb_ilayout') ?
                            \ b:xkb_ilayout : g:XkbSwitchILayout)
                    if switched != ''
                        if switched != cur_layout &&
                                    \ !exists('b:xkb_ilayout_managed')
                            call libcall(g:XkbSwitch['backend'],
                                        \ g:XkbSwitch['set'], switched)
                        endif
                    endif
                endif
            endif
        endif
        if g:XkbSwitchNLayout == ''
            if !b:xkb_pending_imode && (!a:0 || a:1 != 2)
                let b:xkb_nlayout = cur_layout
            endif
        endif
        let b:xkb_pending_imode = a:0 && a:1 == 1
        if b:xkb_pending_imode
            let b:xkb_pending_ilayout = switched != '' ? switched : cur_layout
        endif
    endif
endfun

fun! <SID>xkb_save(...)
    if <SID>skip_buf_or_win()
        return
    endif
    let imode = mode() =~ '^[iR]'
    let save_ilayout_param = s:XkbSwitchSaveILayout && a:0
    if save_ilayout_param && !g:XkbSwitch['local'] &&
                \ (!imode || !s:XkbSwitchFocused)
        return
    endif
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

fun! <SID>xkb_restore_global_layout()
    if empty(s:XkbSwitchGlobalLayout)
        return
    endif
    let cur_layout = libcall(g:XkbSwitch['backend'], g:XkbSwitch['get'], '')
    if cur_layout != s:XkbSwitchGlobalLayout
        call libcall(g:XkbSwitch['backend'], g:XkbSwitch['set'],
                    \ s:XkbSwitchGlobalLayout)
    endif
endfun

fun! <SID>enable_xkb_switch(force)
    if g:XkbSwitchEnabled && !a:force
        return
    endif
    if filereadable(g:XkbSwitch['backend']) == 1
        augroup XkbSwitch
            au!
            " BEWARE: All mappings and syntax rules should be loaded at
            " BufRead event for proper support of Select modes
            if g:XkbSwitchLoadOnBufRead
                autocmd BufRead * call <SID>load_all()
            endif
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
            autocmd VimLeave * call <SID>xkb_restore_global_layout()
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

if !exists('g:leaderf_loaded')
    finish
endif

if !exists('g:Lf_Extensions')
    let g:Lf_Extensions = {}
endif

let g:Lf_Extensions.xkbswitch = {
            \ 'source': 'leaderf#xkbswitch#source',
            \ 'accept': 'leaderf#xkbswitch#accept',
            \ 'bang_enter': 'leaderf#xkbswitch#bang_enter',
            \ 'highlights_def': {
            \ 'Lf_hl_xkbswitchTitle': '.*',
            \ },
            \ 'highlights_cmd': [
            \ 'hi link Lf_hl_xkbswitchTitle Title',
            \ ],
            \ }

