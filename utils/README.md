#### keymap2imaptr.vim

Translate Vim's language keymaps to vim-xkbswitch imap translation files.

Example:

```ShellSession
$ vim -Nesn -u NONE -c 'set keymap=russian-jcukenwin' -S /path/to/keymap2imaptr.vim -c 'w! ru.tr' -cq
$ vim -Nesn -u NONE -c 'set keymap=german-qwertz' -S /path/to/keymap2imaptr.vim -c 'w! de.tr' -cq
```

After making the translation file, make sure that the written language tag such
as *ru* or *de* corresponds to the system keyboard layout name.

Combine translation files if needed:

```ShellSession
$ cat ru.tr de.tr > xkbswitch.tr
ru
< "#$&',./:;<>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^`abcdefghijklmnopqrstuvwxyz{}~
> Э№;?эбю.ЖжБЮ,"ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯхъ:ёфисвуапршолдьтщзйкыегмцчняХЪЁ
de
< "#&'()*+-/:;<>?@YZ[\]^_yz{|}~
> Ä§/ä)=(`ß-Öö;:_"ZYü#+&?zyÜ'*°
```

Right-to-left script languages such as Hebrew or Arabic are not well supported.

