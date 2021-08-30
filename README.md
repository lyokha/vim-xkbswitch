Vim-xkbswitch
=============

by Alexey Radkov and Dmitry Hrabrov a.k.a. DeXPeriX

Table of contents
-----------------

- [About](#about)
- [Features](#features)
- [Setup](#setup)
- [Configuration](#configuration)
    + [Basic configuration](#basic-configuration)
    + [Keymap assistance in Normal mode](#keymap-assistance-in-normal-mode)
    + [Default layouts](#default-layouts)
    + [Disable for specific filetypes](#disable-for-specific-filetypes)
    + [Enable in runtime](#enable-in-runtime)
- [Custom keyboard layout switching rules](#custom-keyboard-layout-switching-rules)
- [Troubleshooting](#troubleshooting)

About
-----

If you speak and write in two or more languages you may know how it's
frustrating to constantly switch keyboard layouts manually, because vim
in command mode can understand only English letters. So you need constantly
change keyboard layout into English if you need perform some command and
if you are writing texts, for example, in Russian, German or Chinese at the
same time.

Vim plugin XkbSwitch can be used to easily switch current keyboard layout back
and forth when entering and leaving Insert mode. Say you are typing some
document in Russian and have to leave Insert mode: when you press ``<Esc>``
your keyboard layout switches to US/English automatically. When you further
enter Insert mode once again the Russian keyboard layout will be automatically
switched back!

XkbSwitch requires OS dependent keyboard layout switcher. Currently it depends
on [xkb-switch](http://github.com/ierton/xkb-switch) for UNIX / X Server and
[xkb-switch-win](http://github.com/DeXP/xkb-switch-win) for Windows.
For Mac OS X you can try
[xkbswitch-macosx](http://github.com/myshov/xkbswitch-macosx) or
[Input Source Switcher](http://github.com/vovkasm/input-source-switcher). In
the latter case you will have to put line

```vim
let g:XkbSwitchLib = '/usr/local/lib/libInputSourceSwitcher.dylib'
```

into your .vimrc settings.

Gnome 3 no longer works correctly with xkb-switch, so consider switching to
[g3kb-switch](http://github.com/lyokha/g3kb-switch) if you are using this
desktop environment. The plugin can be loaded with

```vim
let g:XkbSwitchLib = '/usr/local/lib/libg3kbswitch.so'
```

Features
--------

* Supported OS: UNIX / X Server, Windows, Mac OS X
* Switches keyboard layout when entering / leaving Insert and Select modes
* Keyboard layouts are stored separately for each buffer
* Keyboard layouts are kept intact while navigating between windows or
  tabs without leaving Insert mode
* Automatic loading of language-friendly Insert mode mappings duplicates.
  For example, when Russian mappings have loaded then if there was a mapping

    ```vim
  <C-G>S        <Plug>ISurround
    ```

  a new mapping

    ```vim
  <C-G>Ы        <Plug>ISurround
    ```

  will be loaded. Insert mode mappings duplicates make it easy to apply
  existing maps in Insert mode without switching current keyboard layout.
* Fast and easy building of custom syntax based keyboard layout switching
  rules in Insert mode

Setup
-----

Before installation of the plugin the OS dependent keyboard layout switcher
must be installed (see [About](#about)). The plugin itself is installed by
extracting of the distribution in your vim runtime directory.

Configuration
-------------

### Basic configuration

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
mode user experience. For example, plugin echofunc defines Insert mode
mappings for '(' and ')', therefore assuming that in Deutsch translation map
there could be ')' to '=' translation, we would get '=' unusable in any
keyboard layout (as far as echofunc treats ')' in a very specific way). That
is why this translation is missing in example above and in file xkbswitch.tr
content.

There are multiple examples of similar issues. For instance Russian winkeys
translate '.' into 'ю' and when you are editing a C/C++ source file with
enabled omnicompletion plugin character 'ю' (which you can use in comments)
will always be replaced by '.'. To address these issues starting from **version
0.10** a new variable g:XkbSwitchSkipIMappings was introduced. It defines which
original Insert mode mappings should not be translated for specific filetypes.
Add into your .vimrc lines

```vim
let g:XkbSwitchSkipIMappings =
        \ {'c'   : ['.', '>', ':', '{<CR>', '/*', '/*<CR>'],
        \  'cpp' : ['.', '>', ':', '{<CR>', '/*', '/*<CR>']}
```

and now you will be able to print 'ю' in C and C++ source files. In this
example six Insert mode mappings were prohibited for translation in two
filetypes: C and C++. The first three correspond to omnicompletion plugin and
the last three address plugin c.vim. Why mappings duplicates starting from '/'
were added: Russian winkeys translate '/' into '.' and this makes vim wait for
a while until the next character after '.' has been inserted which makes
omnicompletion plugin almost unusable. If you want to skip specific Insert
mode mappings for all filetypes then you can use '\*' as the filetype key in
g:XkbSwitchSkipIMappings.

Beware: variable g:XkbSwitchSkipIMappings is not parameterized by keyboard
layouts but only by filetypes.

Besides natural Insert mode mappings, register insertion translations are also
supported. For example, being in Insert mode and having Russian winkeys layout
on, you can insert content of register 'a' just printing ``<C-R>ф`` without
switching current keyboard layout. To disable translation of register names in
Insert mode put line

```vim
let g:XkbSwitchLoadRIMappings = 0
```

into your .vimrc.

### Keymap assistance in Normal mode

XkbSwitch is unable to guess keyboard layout when using Normal mode commands
*r* and *f* and searching with */* and *?*. Fortunately it can assist *keymap*
in this by setting

```vim
let g:XkbSwitchAssistNKeymap = 1    " for commands r and f
let g:XkbSwitchAssistSKeymap = 1    " for search lines
```

provided keymap is set to some value, for example

```vim
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
```

Now when you leave Insert mode, the keyboard layout is switched back to the
usual Normal mode value, but values of *iminsert* and *imsearch* are set
depending on the last Insert mode keyboard layout: if it was equal to the
value of b:keymap_name that is normally defined in keymap files then they are
set to 1, otherwise to 0. If keymap names do not match system keyboard layout
names then you can remap them using variable g:XkbSwitchKeymapNames.

```vim
let g:XkbSwitchKeymapNames = {'ru' : 'ru_keymap', 'uk' : 'uk_keymap'}
```

Here *ru* and *uk* are system keyboard layout names whereas *ru_keymap* and
*uk_keymap* are values of b:keymap_name.

When more than two keyboard layouts are used it probably makes sense to set
keymaps dynamically in runtime. XkbSwitch can do it for you! You only need to
define a new variable

```vim
let g:XkbSwitchDynamicKeymap = 1
```

and map g:XkbSwitchKeymapNames to keymap names instead of values of
b:keymap_name. For example

```vim
    let g:XkbSwitchKeymapNames = {'ru' : 'russian-jcukenwin',
                \ 'uk' : 'ukrainian-jcuken'}
```

Now keymap will automatically switch to the last keyboard layout when you
leave Insert mode.

To reset commands *r* and *f* to the usual Normal mode keyboard layout simply
switch to it in Insert mode. To reset search lines press *Ctrl-^*.

There is only one problem not solved so far: the system keyboard layout
indicator when in Normal mode and search lines will show the usual Normal mode
layout. We need some hint that *iminsert* is active and to what language it
points, it also would show what layout will be switched to when we enter
Insert mode again. Very convenient feature, is not?

I will show how to make a keymap indicator for the old
[Powerline](http://github.com/Lokaltog/vim-powerline) plugin, newer offsprings
like [airline](http://github.com/vim-airline/vim-airline) must not differ a lot.

Add lines

```vim
	\ Pl#Segment#Create('keymap_name'     ,
		\'%{&iminsert && exists("b:keymap_name") ? b:keymap_name : ""}',
		\ Pl#Segment#Modes('!N')),
```

into the array passed to Pl#Segment#Init() in file
autoload/Powerline/Segments.vim before the line with *fileformat*, line

```vim
		\ , 'keymap_name'
```

into the list passed to Pl#Theme#Buffer() in file
autoload/Powerline/Themes/default.vim (or whatever theme you are using)
before the line with *fileformat*, and lines

```vim
	\ Pl#Hi#Segments(['keymap_name'], {
		\ 'n': ['brightestorange', 'gray2'],
		\ 'i': ['brightestorange', 'darkestblue'],
		\ }),
	\
```

somewhere into the list passed to Pl#Colorscheme#Init() in file
autoload/Powerline/Colorschemes/default.vim (or whatever Powerline colorscheme
you are using). Then enter command

```vim
    :PowerlineClearCache
```

, restart vim and now the indicator must work (but it will only show keymap
names when *iminsert* is set).

### Default layouts

By default last Normal mode keyboard layout is restored when leaving Insert
mode, but you can specify to use particular layout for that:

```vim
let g:XkbSwitchNLayout = 'us'
```

Also you can specify *original* Insert mode keyboard layout:

```vim
let g:XkbSwitchILayout = 'us'
```

Or *unconditional* Insert mode keyboard layout using buffer variable with the
same name:

```vim
let b:XkbSwitchILayout = 'us'
```

If b:XkbSwitchILayout is set to the empty value then the keyboard layout is not
changed when entering Insert mode. Be aware that momental switching from-and-to
Insert mode (e.g. with Insert mode command ``<C-O>`` and all types of
selections) will turn current keyboard layout to the value of
b:XkbSwitchILayout. If you want to use unconditional Insert mode keyboard layout
by default then put line

```vim
autocmd BufEnter * let b:XkbSwitchILayout = 'us'
```

into your .vimrc (change *us* to desired value if needed).

### Disable for specific filetypes

It makes sense to disable XkbSwitch for buffers with specific filetypes, for
example various file system or tag navigators. For example, to disable
XkbSwitch for NerdTree add in your .vimrc line

```vim
let g:XkbSwitchSkipFt = ['nerdtree']
```

By default (e.g. when g:XkbSwitchSkipFt is not defined in .vimrc) following
filetypes are skipped: *tagbar*, *gundo*, *nerdtree* and *fuf* (FuzzyFinder).

### Enable in runtime

You can enable XkbSwitch in runtime (e.g. when g:XkbSwitchEnabled is not set
in your .vimrc) by issuing command

```vim
:EnableXkbSwitch
```

This command will respect current settings of g:XkbSwitchIMappings etc. Be
aware that there is no way to disable XkbSwitch after it has been enabled.

Custom keyboard layout switching rules
--------------------------------------

Imagine that you are editing a simple dictionary with 2 columns delimited by
vertical bars. In the first column you are writing down a German word and in
the second column - its Russian translation. For example:

```
| Wort         | Übersetzung |
|--------------|-------------|
| der Mond     | луна        |
| humpeln      | хромать     |
| stark        | сильный     |
```

You want the keyboard layout to be automatically switched to the corresponding
language when you are moving between the columns in Insert mode. It is
feasible! When you start editing switch layouts in the both columns manually
just once: after that XkbSwitch will learn how to switch them further. It will
restore layouts after leaving Insert mode and entering it once again.

In this section it will be shown how to achieve this. First of all there
should exist criteria upon which XkbSwitch will decide when it must switch
layouts. The simplest criteria are syntactic rules. So the content of the
columns must be syntactically distinguishable. It means that we need a file
with syntax rules and some new filetype defined, say *mdict*. For the sake of
simplicity let it be not an absolutely new filetype but rather a subclass of
an existing one, for example vimwiki. Then we should create a new file
after/syntax/vimwiki.vim:

```vim
if match(bufname('%'), '\.mdict$') == -1
    finish
endif

let s:colors = {'original':   [189, '#d7d7ff'],
              \ 'translated': [194, '#d7ffd7'],
              \ 'extra':      [191, '#d7ff5f']}

function! s:set_colors()
    let colors = deepcopy(s:colors)
    if exists('g:colors_name') && g:colors_name == 'lucius' &&
                \ g:lucius_style == 'light'
        let colors['original']   = [26,  '#005fd7']
        let colors['translated'] = [22,  '#005f00']
        let colors['extra']      = [167, '#d75f5f']
    endif
    exe 'hi mdictOriginalHl term=standout ctermfg='.colors['original'][0].
                \ ' guifg='.colors['original'][1]
    exe 'hi mdictTranslatedHl term=standout ctermfg='.colors['translated'][0].
                \ ' guifg='.colors['translated'][1]
    exe 'hi mdictExtraHl term=standout ctermfg='.colors['extra'][0].
                \ ' guifg='.colors['extra'][1]
endfunction

syntax match mdictCell '|[^|]*\ze|' containedin=VimwikiTableRow contained
            \ contains=VimwikiCellSeparator,mdictOriginal,mdictTranslated
syntax match mdictOriginal '[^|]\+\ze|\s*\S*.*$' contained contains=mdictExtra
syntax match mdictTranslated '[^|]\+\ze|\s*$' contained contains=mdictExtra
syntax match mdictExtra '([^()]*)' contained

call s:set_colors()
autocmd ColorScheme * call s:set_colors()

hi link mdictOriginal   mdictOriginalHl
hi link mdictTranslated mdictTranslatedHl
hi link mdictExtra      mdictExtraHl
```

Here the syntactic criteria have been defined: content of the first column
will have syntax id *mdictOriginal* and content of the second column -
*mdictTranslated*.

In .vimrc following lines must be added:

```vim
let g:mdict_synroles = ['mdictOriginal', 'mdictTranslated']

fun! MdictCheckLang(force)
    if !filereadable(g:XkbSwitchLib)
        return
    endif

    let cur_synid  = synIDattr(synID(line("."), col("."), 1), "name")

    if !exists('b:saved_cur_synid')
        let b:saved_cur_synid = cur_synid
    endif
    if !exists('b:saved_cur_layout')
        let b:saved_cur_layout = {}
    endif

    if cur_synid != b:saved_cur_synid || a:force
        let cur_layout = ''
        for role in g:mdict_synroles
            if b:saved_cur_synid == role
                let cur_layout =
                    \ libcall(g:XkbSwitchLib, 'Xkb_Switch_getXkbLayout', '')
                let b:saved_cur_layout[role] = cur_layout
                break
            endif
        endfor
        for role in g:mdict_synroles
            if cur_synid == role
                if exists('b:saved_cur_layout[role]')
                    call libcall(g:XkbSwitchLib, 'Xkb_Switch_setXkbLayout',
                                \ b:saved_cur_layout[role])
                else
                    let b:saved_cur_layout[role] = empty(cur_layout) ?
                                \ libcall(g:XkbSwitchLib,
                                \ 'Xkb_Switch_getXkbLayout', '') : cur_layout
                endif
                break
            endif
        endfor
        let b:saved_cur_synid = cur_synid
    endif
endfun

autocmd BufNewFile,BufRead *.mdict setlocal filetype=vimwiki |
           \ EnableXkbSwitch
autocmd BufNewFile         *.mdict VimwikiTable 2 2
autocmd BufNewFile         *.mdict exe "normal dd" | startinsert
autocmd CursorMovedI       *.mdict call MdictCheckLang(0)

let g:XkbSwitchPostIEnterAuto = [
            \ [{'pat': '*.mdict', 'cmd': 'call MdictCheckLang(1)'}, 0] ]
```

Function MdictCheckLang() does all the custom layout switching and can be
regarded as a plugin to the XkbSwitch. The first autocommand states that if
file has extension *.mdict* then its filetype must be *vimwiki* and turns on
XkbSwitch. The next two autocommands are optional and only make editing mdict
files more comfortable. The last autocommand (for CursorMovedI events) calls
MdictCheckLang() when cursor moves into different columns in Insert mode.
The next definition

```vim
let g:XkbSwitchPostIEnterAuto = [
            \ [{'pat': '*.mdict', 'cmd': 'call MdictCheckLang(1)'}, 0] ]
```

registers an InsertEnter autocommand in augroup XkbSwitch. If we had instead
defined an InsertEnter autocommand here then the command would have been put
before the standard InsertEnter autocommand in augroup XkbSwitch. Using variable
g:XkbSwitchPostIEnterAuto ensures that the new command will run after the
standard InsertEnter autocommand. The second element in an item inside
g:XkbSwitchPostIEnterAuto can be 0 or 1. If it is 1 then XkbSwitch won't switch
layout itself when entering Insert mode. In our case it should be 0 because
MdictCheckLang() requires preliminary switching keyboard layout from XkbSwitch
when entering Insert mode.

Starting from **version 0.9** a generic helper for building custom syntax based
keyboard layout switching rules was implemented inside the plugin code.  Now
building syntax rules is as simple as defining variable g:XkbSwitchSyntaxRules
in .vimrc. For example

```vim
let g:XkbSwitchSyntaxRules = [
            \ {'pat': '*.mdict', 'in': ['mdictOriginal', 'mdictTranslated']},
            \ {'ft': 'c,cpp', 'inout': ['cComment', 'cCommentL']} ]
```

registers syntax rules for files with extension *.mdict* (the first element in
g:XkbSwitchSyntaxRules: it replaces our old definitions of g:mdict_synroles,
MdictCheckLang(), autocmd CursorMovedI and g:XkbSwitchPostIEnterAuto) and
comments rules for C and C++ files (the second element in
g:XkbSwitchSyntaxRules). The comments rules define that comments areas may
have their own keyboard layouts in Insert mode and when cursor enters or
leaves them the corresponding layouts must be restored. It may be useful if
a user wants to make comments in a language that uses not standard keyboard
layout without switching layouts back and forth. Notice that the second rule
lists syntax groups in element *inout* whereas the first rule uses element
*in*. The difference is that in the case of the comments rule we want to
restore basic keyboard layout (i.e. layout for code areas) when leaving
comments areas, but in the mdict rule we do not care about leaving areas
*mdictOriginal* and *mdictTranslated* and only care about entering them.

Troubleshooting
---------------

* Some characters from alternative keyboard layouts may fail to enter or behave
  in strange ways for certain filetypes. For example in Russian winkeys layout
  characters 'б', 'ю', 'ж' and 'э' may fail to enter in C++ source files. The
  reason of that is layout translation maps specified in variable
  g:XkbSwitchIMappings. You may work this around by simply not setting this
  variable, or better by specifying characters from the main keyboard layout
  whose translation should be skipped using variable g:XkbSwitchSkipIMappings.
  See details in section [Basic configuration](#basic-configuration).

* There is a known issue when vim-latex package is installed. In this case
  entering Russian symbols in Insert mode when editing tex files becomes
  impossible. The issue arises from clashing XkbSwitch Insert mappings
  duplicates with mappings defined in vim-latex. To work this issue around you
  can disable XkbSwitch Insert mode mappings duplicates for filetype *tex*:

    ```vim
  let g:XkbSwitchIMappingsSkipFt = ['tex']
    ```

* When leaving Insert mode after using an alternative keyboard layout (say
  Russian), there could be a time lag (of length *1 sec* if the value of
  ``timeoutlen`` was not altered) before typing commands in Normal mode gets
  back to produce any effect. To cope with this issue, the value of
  `ttimeoutlen` (notice the *double-t* in the beginning of its name!) must be
  set to some small value, say

    ```vim
  set ttimeoutlen=50
    ```

* *Related to X Server only.* When editing files on a remote host via ssh the
  ssh -X option must be supplied:

    ```sh
  ssh -X remote.host
    ```

  This option will make ssh forward X Server protocol messages between the
  local host and the remote host thus making it possible to switch the local
  host keyboard layouts.

* *Related to GTK based gvim only.* In bare X terminals keycodes for ``<C-S>``
  and ``<C-Ы>`` are the same which makes it possible to leave sequences with
  control keys in Insert mode mappings duplicates as they are. But this is not
  the case in GTK based gvim. The issue is still investigated.

* XkbSwitch supports switching via Select mode too. But there is a case when
  switching from Select mode to Normal mode will fail to restore Normal mode
  keyboard layout. This will happen when leaving Select mode without any
  character having been entered. The reason is simple: vim does not generate
  events that could be caught by autocommands when switching from Select
  mode to Normal mode. A workaround could be: when you are leaving Select
  mode without any character entered do it via Visual mode, e.g. enter
  ``<C-G><Esc>`` instead simply ``<Esc>``.

* There is a clash with plugin EnhancedJumps when *bufhidden=delete*. When
  jumping back to the previous buffer an error message

    ```
  E121: Undefined variable: mappingsdump
    ```

  will raise. This is because both autocommand BufRead of this plugin and
  EnhancedJumps will use *redir* simultaneously which is not permitted.
  Normally there is very little probability to encounter this because option
  *bufhidden* is empty by default. To work this around you can add line

    ```vim
  let g:XkbSwitchLoadOnBufRead = 0
    ```

  in your .vimrc. However this may break the very first keyboard layout
  switching from Select mode in a just open buffer if there was no inserting
  yet.

* If you use *gh*-commands (*gh*, *gH* and *g_CTRL-H*) for your own specific
  purposes then you'll probably want to disable mappings defined for some or
  all of these commands in the plugin. For example

    ```vim
  let g:XkbSwitchSkipGhKeys = ['gh', 'gH']
    ```

    disables plugin mappings for two of them.

