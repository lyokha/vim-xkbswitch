Vim-xkbswitch
=============

by Alexey Radkov and Dmitry Hrabrov a.k.a. DeXPeriX

About
-----

Vim plugin XkbSwitch can be used to easily switch current keyboard layout back
and forth when entering and leaving Insert mode. Say you are typing some
document in Russian and have to leave Insert mode: when you press ```<Esc>```
your keyboard layout switches to US/English automatically. When you further
enter Insert mode once again the Russian keyboard layout will be automatically
switched back!

XkbSwitch requires OS dependent keyboard layout switcher. Currently it depends
on [xkb-switch](http://github.com/ierton/xkb-switch) for UNIX / X Server and [xkb-switch-win](http://github.com/DeXP/xkb-switch-win) for Windows. Mac OS X
keyboard layout switcher is currently unknown and hence not supported.

Features
--------

* Supported OS: UNIX / X Server, Windows
* Switches keyboard layout when entering / leaving Insert and Select mode
* Keyboard layouts are stored separately for each buffer
* Automatic loading of language-friendly Insert mode mappings duplicates.
  For example when Russian mappings have loaded then if there was a mapping

  ```vim
  <C-G>S        <Plug>ISurround
  ```

  a new mapping

  ```vim
  <C-G>Ы        <Plug>ISurround
  ```

  will be loaded. Insert mode mappings duplicates make it easy to apply
  existing maps in Insert mode without switching current keyboard layout.

Setup
-----

Before installation of the plugin the OS dependent keyboard layout switcher
must be installed (see About). The plugin itself is installed by
extracting of the distribution in your vim runtime directory.

Configuration
-------------

Basic configuration requires only 1 line in your .vimrc:

```vim
let g:XkbSwitchEnabled = 1
```

Additionally path to the backend switcher library can be defined:

```vim
let g:XkbSwitchLib = '/usr/local/lib/libxkbswitch.so'
```

However normally it is not necessary as far as the plugin is able to find it
automatically. To enable Insert mode mappings duplicates user may want to add

```vim
let g:XkbSwitchIMappings = ['ru']
```

Here Insert mappings duplicates for Russian winkeys layout will be generated
whenever Insert mode is started. It is possible to define a list of different
layouts, for example

```vim
let g:XkbSwitchIMappings = ['ru', 'de']
```

but currently only Russian winkeys layout translation map ('ru') is supported
out of the box. There are 2 ways how a user can provide extra definitions of
keyboard layout translation maps (or replace existing default 'ru' map):

* Define variable g:XkbSwitchIMappingsTr:

  ```vim
  let g:XkbSwitchIMappingsTr = {
              \ 'ru':
              \ {'<': 'qwertyuiop[]asdfghjkl;''zxcvbnm,.`/'.
              \       'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|',
              \  '>': 'йцукенгшщзхъфывапролджэячсмитьбюё.'.
              \       'ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё"№;:?/'},
              \ 'de':
              \ {'<': 'yz-[];''/YZ{}:"<>?~@#^&*_\',
              \  '>': 'zyßü+öä-ZYÜ*ÖÄ;:_°"§&/(?#'},
              \ }
  ```

* Create a file with layout translation maps and put its path into variable
  g:XkbSwitchIMappingsTrData, for example:

  ```vim
  let g:XkbSwitchIMappingsTrData = $HOME.'/opt/xkbswitch.tr'
  ```

  File with maps must follow this format:

  ```
  ru  Russian winkeys layout
  < qwertyuiop[]asdfghjkl;'zxcvbnm,.`/QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|
  > йцукенгшщзхъфывапролджэячсмитьбюё.ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё"№;:?/

  de
  < yz-[];'/YZ{}:"<>?~@#^&*(_\
  > zyßü+öä-ZYÜ*ÖÄ;:_°"§&/()?#
  ```

  Sample file xkbswitch.tr with exactly this content is shipped with this
  plugin distribution. It is encoded in UTF-8 and it is important as far as
  its content is read using readfile()! If your locale is not UTF-8 and
  you want to use this sample file then it seems that you will have to
  re-encode it in your locale standard encoding

Be very careful with mapping duplicates! They won't replace existing Insert
mode mappings but may define extra mappings that will change normal Insert
mode user experience. For example plugin echofunc defines Insert mode mappings
for '(' and ')', therefore assuming that in Deutsch translation map there
could be ')' to '=' translation, we would get '=' unusable in any keyboard
layout (as far as echofunc treats ')' in a very specific way). That is why
this translation is missing in example above and in file xkbswitch.tr content.

You can enable XkbSwitch in runtime (e.g. when g:XkbSwitchEnabled is not set
in your .vimrc) by issuing command

```vim
:EnableXkbSwitch
```

This command will respect current settings of g:XkbSwitchIMappings etc. Be
aware that there is no way to disable XkbSwitch after it has been enabled.

