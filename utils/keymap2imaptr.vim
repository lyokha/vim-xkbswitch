put! =execute('lmap')
%!sed 's/^l\s\+//; /^\S\{2,\}\|^$/d; s/\(^\S\)\s\+\*\?@/\1\t/'
%!awk '{from=from$1; to=to$2} END {print "< " from "\n> " to}'
put! =b:keymap_name

