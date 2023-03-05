" Translate Vim's language keymaps to vim-xkbswitch imap translation files
"
" Example:
"
" $ vim -Nesn -u NONE -c 'set keymap=russian-jcukenwin' -S /path/to/keymap2imaptr.vim -c 'w! ru.tr' -cq
" $ vim -Nesn -u NONE -c 'set keymap=german-qwertz' -S /path/to/keymap2imaptr.vim -c 'w! de.tr' -cq
"
" After making the translation file, make sure that the written language tag
" such as 'ru' or 'de' corresponds to the system keyboard layout name.
"
" Combine translation files if needed:
"
" $ cat ru.tr de.tr > xkbswitch.tr
"
" Right-to-left script languages such as Hebrew or Arabic are not well
" supported.

put! =execute('lmap')
%!sed 's/^l\s\+//; /^\S\{2,\}\|^$/d; s/\(^\S\)\s\+\*\?@/\1\t/'
%!awk '{from=from$1; to=to$2} END {print "< " from "\n> " to}'
put! =b:keymap_name

