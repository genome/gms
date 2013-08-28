" _vimrc
"
" Settings for both terminal and GUI Vim sessions.
" (See _gvimrc for GUI-specific settings.)
"
" Last modified Thu Jan 29 09:28:58 2009
" 

" firefox style tab navigation
:nmap <S-tab> :tabn<CR>
:imap <S-tab> <Esc>:tabn<CR>i
":nmap <C-S-tab> :tabprevious<CR>
":nmap <C-tab> :tabnext<CR>
":map <C-S-tab> :tabprevious<CR>
":map <C-tab> :tabnext<CR>
":imap <C-S-tab> <Esc>:tabprevious<CR>i
":imap <C-tab> <Esc>:tabnext<CR>i
":nmap <C-t> :tabnew<CR>
":imap <C-t> <Esc>:tabnew<CR>

" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
    finish
endif

" Use Vim settings instead of Vi settings. Set this early,
" as it changes many other options as a side effect.
set nocompatible

" Load miscellaneous functions used elsewhere in this file.
runtime misc_functions.vim

" Don't show the Vim welcome screen.
set shortmess+=I

" Allow backspacing over everything in insert mode.
set backspace=indent,eol,start

" Copy indent from current line when starting a new line,
" but turn off 'smartindent'. (It messes up right-shifting
" of lines starting with '#'.)
set autoindent
set nosmartindent

" Command-line history to remember.
set history=500

" Always show the cursor position.
set ruler

" Display incomplete commands.
set showcmd

" Do incremental searching.
set incsearch

" Highlight latest search pattern.
set hlsearch

" Display line numbers.
set number

" Always show a status line.
set laststatus=2

" Minimum number of columns to show for line numbers.
set numberwidth=4

" Number of context lines at the top and bottom of the display.
set scrolloff=3

" Number of context columns at the left and right of the display.
set sidescrolloff=5

" Number of characters to scroll when scrolling sideways.
set sidescroll=1

" Don't wrap the display of long lines.
set nowrap

" When 'wrap' is on, wrap at a 'breakat' char instead of the display edge.
set linebreak

" Insert spaces when <Tab> is pressed, and use spaces for indentation.
set expandtab

" Make <Tab> respect 'shiftwidth', 'tabstop', and 'softtabstop' settings.
set smarttab

" Set the number of spaces to use for indent and unindent.
set shiftwidth=2

" Round indent to a multiple of 'shiftwidth'.
set shiftround

" Set the visible width of tabs.
set tabstop=2

" Edit as if tabs are 2 characters wide.
set softtabstop=2

" Ignore case for pattern matches (use \C to override).
set ignorecase

" Override 'ignorecase' if the search pattern contains uppercase characters.
set smartcase

" Don't allow searches to wrap around EOF.
set nowrapscan

" Don't highlight the current screen line or column.
set nocursorline
set nocursorcolumn

" Allow virtual editing when in Visual block mode
set virtualedit=block

" Avoid all beeping and flashing by first turning on the visual bell,
" and then setting the visual bell to nothing.
set vb t_vb=

" Don't show listchars by default, since it interferes with
" linebreak / breakat wrapping.
set nolist

" What to show when 'list' is on.
set listchars=tab:þ¬,trail:·,extends:§,precedes:§

" Characters that form pairs, for use with % and the 'showmatch' option.
set matchpairs=(:),[:],{:},<:>

" Don't jump to matching paired characters (see 'matchpairs' setting).
set noshowmatch
set matchtime=1 " in milliseconds, when showmatch is on

" Number of columns to show at left for folds.
set foldcolumn=3

" Only allow 3 levels of folding.
set foldnestmax=3

" Start with all folds open.
set foldlevelstart=99

" Allow left/right arrow keys to move to the next/previous line.
set whichwrap+=<,>,[,]

" Display as much of the last line in a window as possible. (When not
" included, a last line that doesn't fit is replaced with "@" lines.)
set display=lastline

" Ignore modelines. I don't use them, and I don't like files messing
" with my settings.
set nomodeline

" Don't get fancy with the spaces when joining lines.
set nojoinspaces


" 
" Backup files
"

" Keep a backup file for all platforms except VMS.
" (VMS supports automatic versioning.)
"
if has("vms")
    set nobackup
else
    set backup
endif

" Prepend OS-appropriate temporary directories to the backupdir list.
"
if has("unix") " (including OS X)

    " Remove the current directory from the backup directory list.
    set backupdir-=.

    " Save backup files in the current user's ~/tmp directory,
    " or in the system /tmp directory if that's not possible.
    set backupdir^=~/tmp,/tmp

    " Try to put swap files in ~/tmp (using the munged full pathname of
    " the file to ensure uniqueness). Use the same directory
    " as the current file if ~/tmp isn't available.
    set directory=~/tmp//,.

elseif has("win32")

    " Remove the current directory from the backup directory list.
    set backupdir-=.

    " Save backup files in the current user's TEMP directory
    " (that is, whatever the TEMP environment variable is set to).
    set backupdir^=$TEMP

endif


"
" Autocommands
"

if has("autocmd")

    " Remove all autocommands for the current group.
    autocmd!

    " Enable file type detection. Use the default filetype settings, so
    " that mail gets 'tw' set to 72, 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent
    " indenting.
    filetype plugin indent on

    " For text files, wrap on-screen, and insert linebreaks.
    autocmd BufReadPost *.txt   setlocal wrap textwidth=72

    " For mail, wrap on-screen, but don't insert hard linebreaks.
    autocmd FileType mail       setlocal wrap textwidth=0

    " For .cfg files:
    " - Automatically insert comment leader after <Enter> in Insert mode (+=r)
    " - Do not auto-wrap text or comments using textwidth (-=tc)
    "
    autocmd BufReadPost *.cfg   setlocal formatoptions+=r formatoptions-=tc

    " XXX: These settings should probably be handled via a plugin.
    "
    autocmd BufNewFile,BufRead *.mxml   set filetype=mxml
    autocmd BufNewFile,BufRead *.as     set filetype=actionscript

    " Use perldoc as the keyword-lookup program when editing Perl files.
    autocmd FileType perl setlocal keywordprg=perldoc
    
    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    "
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

endif " has("autocmd")


" Switch syntax highlighting on when the terminal has colors.
" Expand the syntax menu.
" 
" XXX: This doesn't work under recent MacVim versions. Haven't
" yet taken the time to figure out why.
"
if &t_Co > 2 || has("gui_running")
    let do_syntax_sel_menu=1
    syntax on
endif

" Set 'selection', 'selectmode', 'mousemodel' and 'keymodel' for
" Windows-like behavior. Specifically:
"
"     set selection=exclusive
"     set selectmode=mouse,key
"     set mousemodel=popup
"     set keymodel=startsel,stopsel
"
behave mswin

" These settings are taken from the $VIMRUNTIME/mswin.vim file,
" which is normally used to make Vim behave more like a native
" MS-Windows application. I don't source that file any longer,
" but I still want some of the settings (for the moment).
"
if has("win32")

    " backspace in Visual mode deletes selection
    vnoremap <BS> d

    " CTRL-X and SHIFT-Del are Cut
    vnoremap <C-X>      "+x
    vnoremap <S-Del>    "+x

    " CTRL-C and CTRL-Insert are Copy
    vnoremap <C-C>      "+y
    vnoremap <C-Insert> "+y

    " CTRL-V and SHIFT-Insert are Paste
    map <C-V>           "+gP
    map <S-Insert>      "+gP

    cmap <C-V>          <C-R>+
    cmap <S-Insert>     <C-R>+

    " Pasting blockwise and linewise selections is not possible in Insert and
    " Visual mode without the +virtualedit feature.  They are pasted as if they
    " were characterwise instead.
    " Uses the paste.vim autoload script.

    exe 'inoremap <script> <C-V>' paste#paste_cmd['i']
    exe 'vnoremap <script> <C-V>' paste#paste_cmd['v']

    imap <S-Insert>     <C-V>
    vmap <S-Insert>     <C-V>

    " Use CTRL-Q to do what CTRL-V used to do
    noremap <C-Q>       <C-V>

    " CTRL-F4 is Close window
    noremap <C-F4> <C-W>c
    inoremap <C-F4> <C-O><C-W>c
    cnoremap <C-F4> <C-C><C-W>c
    onoremap <C-F4> <C-C><C-W>c

    " For CTRL-V to work autoselect must be off.
    " On Unix we have two selections, autoselect can be used.
    "
    if !has("unix")
        set guioptions-=a
    endif

    " Alt-Space is System menu
    "
    if has("gui")
        noremap <M-Space> :simalt ~<CR>
        inoremap <M-Space> <C-O>:simalt ~<CR>
        cnoremap <M-Space> <C-C>:simalt ~<CR>
    endif

endif


" 
" Colors
"

" colorscheme ssmith


"
" Key mappings
"
" XXX: Consider moving these to their own file.
"

" Control+A is Select All.
" 
noremap  <C-A>  gggH<C-O>G
inoremap <C-A>  <C-O>gg<C-O>gH<C-O>G
cnoremap <C-A>  <C-C>gggH<C-O>G
onoremap <C-A>  <C-C>gggH<C-O>G
snoremap <C-A>  <C-C>gggH<C-O>G
xnoremap <C-A>  <C-C>ggVG

" Control+S saves the current file (if it's been changed).
"
noremap  <C-S>  :update<CR>
vnoremap <C-S>  <C-C>:update<CR>
inoremap <C-S>  <C-O>:update<CR>

" Control+Z is Undo, in Normal and Insert mode.
"
noremap  <C-Z>  u
inoremap <C-Z>  <C-O>u

" Control+Y is Redo (although not repeat), in Normal and Insert mode.
" 
noremap  <C-Y>      <C-R>
inoremap <C-Y>      <C-O><C-R>

" Control+Tab moves to the next window.
"
"noremap  <C-Tab>    <C-W>w
"inoremap <C-Tab>    <C-O><C-W>w
"cnoremap <C-Tab>    <C-C><C-W>w
"onoremap <C-Tab>    <C-C><C-W>w

" F2 inserts the date and time at the cursor.
"
inoremap <F2>   <C-R>=strftime("%c")<CR>
nnoremap <F2>   a<F2><Esc>

" F7 formats the current/highlighted paragraph.
"
" Idea from VimTimp347:
" http://vim.wikia.com/wiki/Format_paragraph_without_changing_the_cursor_position
"
" It may be more desirable to preserve the cursor's logical position (i.e.,
" which word it is currently on), rather than its line/col position.  The
" following nmap does this by inserting a small and unusual bogus text at the
" current cursor position; formatting the paragraph; using search to get to
" the bogus word; and then deleting it.
"
"   nmap gb i<zqfm><esc>gqip?<zqfm><cr>df>
"
nnoremap <F7>   gqap
inoremap <F7>   <Esc>gqapi
vnoremap <F7>   gq

" Shift+F7 joins all lines of the current paragraph or highlighted block
" into a single line.
"
nnoremap <S-F7>     vipJ
inoremap <S-F7>     <Esc>vipJi
vnoremap <S-F7>     J

" Tab/Shift+Tab indent/unindent the highlighted block (and maintain
" the Visual selection after changing the indentation).
" 
vmap <Tab>      >gv
vmap <S-Tab>    <gv

" Make cursor keys ignore soft-wrapping
"
" XXX: This doesn't work when marking selections with shifted
" arrow keys. Experiment with vmap/xmap/smap.
" 
inoremap <Up>       <C-O>gk
inoremap <Down>     <C-O>gj

nnoremap <Up>       gk
nnoremap <Down>     gj

xnoremap <Up>       gk
xnoremap <Down>     gj
xnoremap <Left>     h
xnoremap <Right>    l

" Disable paste-on-middle-click.
"
map  <MiddleMouse>      <Nop>
map  <2-MiddleMouse>    <Nop>
map  <3-MiddleMouse>    <Nop>
map  <4-MiddleMouse>    <Nop>
imap <MiddleMouse>      <Nop>
imap <2-MiddleMouse>    <Nop>
imap <3-MiddleMouse>    <Nop>
imap <4-MiddleMouse>    <Nop>

" Control+Backslash toggles search/match highlighting and
" display of 'listchar' characters. (This is all inline because
" the :nohlsearch command doesn't work inside a user function.)
"
" XXX: This works great, except that list/nolist isn't a good marker.
" Have to hit the keystroke twice the first time it's used.
" These may be useful:
"   :set invlist
"   :set invhlsearch
" 
map  <silent> <C-Bslash>     :if &list <Bar> nohlsearch <Bar> set nolist <Bar> match none <Bar> else <Bar> set hlsearch <Bar> set list <Bar> endif<CR>
imap <silent> <C-BSlash>     <Esc><C-BSlash>a
vmap <silent> <C-BSlash>     <Esc><C-BSlash>gv

" Control+Arrows move lines/selections up and down.
" (From a comment found in http://www.vim.org/tips/tip.php?tip_id=646)
"
nmap <C-Up>     :m-2<CR>
nmap <C-Down>   :m+<CR>
imap <C-Up>     <C-O>:m-2<CR><C-O>
imap <C-Down>   <C-O>:m+<CR><C-O>
vmap <C-Up>     :m'<-2<CR>
vmap <C-Down>   :m'>+<CR>


if has("gui_macvim")

    " See MacVim.app/Contents/Resources/vim/gvimrc for details on these
    " settings.

    " Enable HIG Command and Option movement mappings.
    " by *not* setting macvim_skip_cmd_opt_movement.
    " (That is, *don't* skip mapping them.)

    " Enable HIG shift movement settings.
    let macvim_hig_shift_movement = 1

    " XXX: These were the mappings I was using before I discovered the
    " two settings above. They're disabled now.
    "
    if 0 " ...in other words, never
        
        " Shift+Command+(left/right arrow key) select to beginning/end
        " of current line.
        "
        noremap  <S-D-Left>     gh<C-O>0
        noremap  <S-D-Right>    gh<C-O>$
        inoremap <S-D-Left>     <C-O>gh<C-O>0
        inoremap <S-D-Right>    <C-O>gh<C-O>$
        vnoremap <S-D-Right>    $
        vnoremap <S-D-Left>     0

    endif

endif

" Make Option+Arrows do the same thing that Control+Arrows do (to match
" Eclipse/FlexBuilder).
"
" Remove the existing mappings first, or the new ones won't take.
"
" XXX: For some reason, this doesn't stick. It doesn't always work.
"
"nunmap <M-Up>
"nunmap <M-Down>
"iunmap <M-Up>
"iunmap <M-Down>
"vunmap <M-Up>
"vunmap <M-Down>
"
" Map Option+Arrows to the Control+Arrows mappings above.
"
nmap <M-Up>     <C-Up>
nmap <M-Down>   <C-Down>
imap <M-Up>     <C-Up>
imap <M-Down>   <C-Down>
vmap <M-Up>     <C-Up>
vmap <M-Down>   <C-Down>


" Control+Hyphen (yes, I know it says underscore) repeats
" the character above the cursor.
"
inoremap <C-_>  <C-Y>

" Center the display line after searches.
" (This makes it *much* easier to see the matched line.)
"
" More info: http://www.vim.org/tips/tip.php?tip_id=528
"
nnoremap n      nzz
nnoremap N      Nzz
nnoremap *      *zz
nnoremap #      #zz
nnoremap g*     g*zz
nnoremap g#     g#zz


" Draw lines of dashes or equal signs based on the length of the
" line immediately above.
"
nnoremap <Leader>h-     kyyp^v$r-o
nnoremap <Leader>h=     kyyp^v$r=o

" Comma+SingleQuote toggles single/double quoting of the current string.
" 
runtime switch_quotes.vim
map <silent> ,'     :call SwitchQuotesOnCurrentString()<CR>

" Set the filetype for the current buffer to JavaScript (for syntax
" highlighting), then format the current buffer as indented JSON.
" Requires format-json.pl in ~/bin directory.
"
map ,j      :set filetype=javascript<CR>:%!perl ~/bin/format-json.pl<CR>

" Format the highlighted text as JSON.
vmap ,j     :!perl ~/bin/format-json.pl<CR>

" Edit .vimrc, _vimrc, etc.
" 
" XXX: Would be nice if this automatically opened a new buffer/window/etc.
" Behavior may differ depending on GUI vs. terminal.
"
map ,ev     :edit $MYVIMRC<CR>


" XXX: Can't do this yet. Control+Period isn't recognized.
"inoremap <C-.>  <C-N>

" Space over to match spacing on first previous non-blank line.
imap <expr> <S-Tab> InsertMatchingSpaces()


"
" Abbreviations
"

runtime set_abbreviations.vim


" end _vimrc
