if !exists('g:XkbSwitchProgram')
	if g:XkbSwitchLib =~# 'libxkbswitch'
		let g:XkbSwitchProgram = 'xkb-switch'
	else
		let g:XkbSwitchProgram = 'g3kb-switch'
	endif
endif

function! leaderf#xkbswitch#source(args) abort "{{{
	return split(system(g:XkbSwitchProgram .. ' -l'))
endfunction "}}}

function! leaderf#xkbswitch#accept(line, args) abort "{{{
	let b:xkb_ilayout = a:line
endfunction "}}}

function! leaderf#xkbswitch#bang_enter(orig_buf_nr, orig_cursor, args) abort "{{{
	call search(get(g:, 'XkbSwitchNLayout', ''))
	redraw
endfunction "}}}
