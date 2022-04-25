" DO NOT MAKE CHANGES TO THIS FILE =================================
" Instead, place custom changes in $HOME/.vim/plugin/rc.vim

" GLOBAL SETTINGS ==================================================
set nocompatible
syntax on
filetype on

let mapleader=","
set path+=$VIMRUNTIME
set laststatus=2 cmdheight=2 mousehide wrap number nofoldenable
set ai nocindent ignorecase expandtab incsearch hlsearch
set tabstop=3 shiftwidth=3 previewheight=24 formatoptions=l backspace=indent,eol,start t_kb=
set splitright nosplitbelow noequalalways linebreak showbreak=\ \ \
set sessionoptions+=winpos,resize
set statusline=%<%f%h%w%m%r%=%l\ of\ %L\ col\ %c%V,\ char\ %o\ %P\ x%B
set encoding=utf-8
set cpo-=<
set background=light
set guioptions+=b
set guioptions-=T
set fileformats=dos,mac,unix
set printoptions=header:0
set mps+=<:>
set viminfo='50,n$HOME/.vim/.viminfo
set ffs=unix,dos,mac
set backup
set writebackup
set backupdir=$HOME/.vim/save//
set directory=$HOME/.vim/swp//
set undodir=$HOME/.vim/undo//
set patchmode=.save
set cursorline
set t_Co=256
set timeout
set timeoutlen=500
set t_BE=
let c_minlines=400
let savevers_dirs=&backupdir
let g:showmarks_hlline_upper=1
let g:showmarks_include="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
let g:MultipleSearchColorSequence="#ffff33,#99ff99,#aaffff,#ccccff,#ffcccc"
let g:MultipleSearchTextColorSequence="#000000,#000000,#000000,#000000,#000000"
let g:MultipleSearchMaxColors=5
let g:bufExplorerSortBy='name'
let g:bufExplorerShowRelativePath=1

colorscheme summerfruit256
hi MyGroup ctermfg=0 ctermbg=219 guifg=#000000 guibg=#ffafff
hi ColorColumn ctermbg=255 guibg=#eeeeee

hi DiffAdd     term=bold ctermfg=16  ctermbg=193 guifg=#000000 guibg=#d7ffaf
hi DiffChange  term=bold ctermfg=16  ctermbg=254 guifg=#000000 guibg=#e4e4e4
hi DiffText    term=bold ctermfg=16  ctermbg=222 guifg=#000000 guibg=#ffd787
hi DiffDelete  term=bold ctermfg=225 ctermbg=225 guifg=#ffd7ff guibg=#ffd7ff

fu! RefreshEggHighlighting()
   let P_Name=':[a-zA-Z0-9\.-]\+'
   let P_Dir_Name='\(' . P_Name . '\|' . ':[a-zA-Z0-9\.-]\+/[a-zA-Z0-9\.-]\+' . '\)'
   let P_RE='\(' . '@\?' . '\|' . P_Name . '\|' . '@' . P_Name . '\)'
   let P_Dir_RE='\(' . '@\?' . '\|' . P_Dir_Name . '\|' . '@' . P_Dir_Name . '\)'

   let C_Name=':[%a-zA-Z][%a-zA-Z0-9_\.-]*'
   let C_RE='\(' . '+\?' . '\(' . P_Name . '\)\?' . '\(' . C_Name . '\)\?' . '\)'
   let C_Dir_RE='\(' . '+\?' . '\(' . P_Dir_Name . '\)\?' . '\(' . C_Name . '\)\?' . '\)'

   let U_Name=':[%a-zA-Z][%a-zA-Z0-9_\.-]*'
   let U_RE='\(' . '\(' . U_Name . '\)\?' . '\|' . '\(' . '-' . '\|' . '-\?' . C_Name . '\)' . U_Name . '\)'

   let FunctionRE='\.\{0,2}\([a-zA-Z_:%=-][a-zA-Z0-9_,:%.+-]*\)\?'
   let FunctionAsVarRE='\(_[a-zA-Z0-9_]*\(\[[^]]*\]\)\?\)'

   let P_Variable='(@' . P_RE . ')' . FunctionAsVarRE
   let P_Function_Decl='^@\s\+' . FunctionRE . '\s*(\s*)'
   let P_Function_Ref='(@' . P_RE . ')::\?' . FunctionRE
   let P_Directory='(@' . '\(' . P_Dir_RE .'\)' . ')/'

   let C_Variable='(+' . C_RE . ')' . FunctionAsVarRE
   let C_Function_Decl='^+\s\+' . FunctionRE . '\s*(\s*)'
   let C_Function_Ref='(+' . C_RE . ')::\?' . FunctionRE
   let C_Directory='(+' . '\(' . C_Dir_RE .'\)' . ')/'

   let U_Variable='(-' . U_RE . ')' . FunctionAsVarRE
   let U_Function_Decl='^-\s\+' . FunctionRE . '\s*(\s*)'
   let U_Function_Ref='(-' . U_RE . ')::\?' . FunctionRE
   let U_Directory='(-' . '\(' . U_RE .'\)' . ')/'

   let F_Variable='(\.)' . FunctionAsVarRE

   let E_AndOr='\((||)\|(&&)\)'
   let E_Closure='\(({[^)]*)\|(})\)'
   let E_Token='\((%[^%]\+%)\)'

   " Highlighting for in-use BashG macros
   call matchadd('bashgAndOr', E_AndOr, -1)
   call matchadd('bashgClosure', E_Closure, -1)
   call matchadd('bashgToken', E_Token, -1)

   call matchadd('bashgPackageFunctionDecl', P_Function_Decl, -1)
   call matchadd('bashgPackageFunction', '(@' . P_RE . ')', -1)
   call matchadd('bashgPackageFunction', P_Function_Ref, -1)
   call matchadd('bashgPackageDirectory', P_Directory, -1)
   call matchadd('bashgPackageVariable', P_Variable, -1)

   call matchadd('bashgComponentFunctionDecl', C_Function_Decl, -1)
   call matchadd('bashgComponentFunction', C_Function_Ref, -1)
   call matchadd('bashgComponentDirectory', C_Directory, -1)
   call matchadd('bashgComponentVariable', C_Variable, -1)

   call matchadd('bashgUnitFunctionDecl', U_Function_Decl, -1)
   call matchadd('bashgUnitFunction', U_Function_Ref, -1)
   call matchadd('bashgUnitDirectory', U_Directory, -1)
   call matchadd('bashgUnitVariable', U_Variable, -1)

   call matchadd('bashgFunctionVariable', F_Variable, -1)

   " Escaped highlighting for BashG macros
   call matchadd('bashgEscaped','^\\' . '@\s\+' . FunctionRE . '\s*(\s*)', -1)
   call matchadd('bashgEscaped','\\' . '(@' . P_RE . ')', -1)
   call matchadd('bashgEscaped','\\' . P_Function_Ref, -1)
   call matchadd('bashgEscaped','\\' . P_Directory, -1)
   call matchadd('bashgEscaped','\\' . P_Variable, -1)

   call matchadd('bashgEscaped','^\\' . '+\s\+' . FunctionRE . '\s*(\s*)', -1)
   call matchadd('bashgEscaped','\\' . C_Function_Ref, -1)
   call matchadd('bashgEscaped','\\' . C_Directory, -1)
   call matchadd('bashgEscaped','\\' . C_Variable, -1)

   call matchadd('bashgEscaped','^\\' . '-\s\+' . FunctionRE . '\s*(\s*)', -1)
   call matchadd('bashgEscaped','\\' . U_Function_Ref, -1)
   call matchadd('bashgEscaped','\\' . U_Directory, -1)
   call matchadd('bashgEscaped','\\' . U_Variable, -1)

   call matchadd('bashgEscaped','\\' . F_Variable, -1)

   call matchadd('bashgEscaped','\\' . E_AndOr, -1)
   call matchadd('bashgEscaped','\\' . E_Closure, -1)
   call matchadd('bashgEscaped','\\' . E_Token, -1)

   " Comments
   call matchadd('bashgComment','^\s*\zs#.*$', -1)
   call matchadd('bashgComment','^\s\zs#.*$', -1)

   echo
endfunc

" Fonts
fu! FontBigger()
    try
        throw $currentFontSize
    catch /^6/
        se guifont=Lucida\ Console\ Semi-Condensed\ 8
        let $currentFontSize=8
    catch /^8/
        se guifont=Lucida\ Console\ Semi-Condensed\ 9
        let $currentFontSize=9
    catch /^9/
        se guifont=Lucida\ Console\ Semi-Condensed\ 10
        let $currentFontSize=10
    catch /^10/
        se guifont=Lucida\ Console\ Semi-Condensed\ 11
        let $currentFontSize=11
    catch /^11/
        se guifont=Lucida\ Console\ Semi-Condensed\ 12
        let $currentFontSize=12
    catch /^12/
        se guifont=Lucida\ Console\ Semi-Condensed\ 14
        let $currentFontSize=14
    catch /^14/
        se guifont=Lucida\ Console\ Semi-Condensed\ 16
        let $currentFontSize=16
    catch /^16/
        se guifont=Lucida\ Console\ Semi-Condensed\ 18
        let $currentFontSize=18
    catch /^18/
        se guifont=Lucida\ Console\ Semi-Condensed\ 24
        let $currentFontSize=24
    catch /^24/
        se guifont=Lucida\ Console\ Semi-Condensed\ 36
        let $currentFontSize=36
    catch /^36/
        se guifont=Lucida\ Console\ Semi-Condensed\ 48
        let $currentFontSize=48
    catch /^48/
        se guifont=Lucida\ Console\ Semi-Condensed\ 72
        let $currentFontSize=72
    catch /.*/
    endtry
endfunc

fu! FontSmaller()
    try
        throw $currentFontSize
    catch /^72/
        se guifont=Lucida\ Console\ Semi-Condensed\ 48
        let $currentFontSize=48
    catch /^48/
        se guifont=Lucida\ Console\ Semi-Condensed\ 36
        let $currentFontSize=36
    catch /^36/
        se guifont=Lucida\ Console\ Semi-Condensed\ 24
        let $currentFontSize=24
    catch /^24/
        se guifont=Lucida\ Console\ Semi-Condensed\ 18
        let $currentFontSize=18
    catch /^18/
        se guifont=Lucida\ Console\ Semi-Condensed\ 16
        let $currentFontSize=16
    catch /^16/
        se guifont=Lucida\ Console\ Semi-Condensed\ 14
        let $currentFontSize=14
    catch /^14/
        se guifont=Lucida\ Console\ Semi-Condensed\ 12
        let $currentFontSize=12
    catch /^12/
        se guifont=Lucida\ Console\ Semi-Condensed\ 11
        let $currentFontSize=11
    catch /^11/
        se guifont=Lucida\ Console\ Semi-Condensed\ 10
        let $currentFontSize=10
    catch /^10/
        se guifont=Lucida\ Console\ Semi-Condensed\ 9
        let $currentFontSize=9
    catch /^9/
        se guifont=Lucida\ Console\ Semi-Condensed\ 8
        let $currentFontSize=8
    catch /^8/
        se guifont=Lucida\ Console\ Semi-Condensed\ 6
        let $currentFontSize=6
    catch /.*/
    endtry
endfunc

let $currentFontSize=11
call FontBigger()

" Toggle word wrapping
let $wrapState=0
fu! ToggleWrap()
    if $wrapState == 0
        set wrap
        windo set wrap
        let $wrapState=1
    else
        set nowrap
        windo set nowrap
        let $wrapState=0
    endif
endfunc
map ,w :call ToggleWrap()<CR>
call ToggleWrap()

" Formatting
let $formatState=2
fu! ToggleFormat()
   if $formatState == 0
      map ,f !'efmt -w90<CR>
      let $formatState=1
      echo "Formatting now wraps at 90"
   elseif $formatState == 1
      map ,f !'efmt -w100<CR>
      let $formatState=2
      echo "Formatting now wraps at 100"
   else
      map ,f !'efmt -w80<CR>
      let $formatState=0
      echo "Formatting now wraps at 80"
   endif
endfunc
map ,F :call ToggleFormat()<CR>
map ,f !'efmt -w100<CR>

" Toggle Remove Trailing Spaces on Save
let $removeTrailingSpacesState=1
fu! ToggleRemoveTrailingSpaces()
   if $removeTrailingSpacesState == 0
      let $removeTrailingSpacesState=1
      echo "Removing trailing spaces"
   else
      let $removeTrailingSpacesState=0
      echo "Not removing trailing spaces"
   endif
endfunc
map ,s :call ToggleRemoveTrailingSpaces()<CR>

fu! RemoveTrailingSpaces()
   if $removeTrailingSpacesState == 1
      let l = line(".")
      let c = col(".")
      %s/\s\+$//e
      call cursor(l, c)
   endif
endfunc
auto BufWritePre * call RemoveTrailingSpaces()

" Toggle what happens when you press the ENTER key (selection)
fu! ToggleKeywordIsPropertyState()
    if $nextKeywordIsPropertyState == 0
        set iskeyword=@,47-57,_,192-255,.
        let $nextKeywordIsPropertyState=1
        echo "ENTER key now also selects dotted properties"
    elseif $nextKeywordIsPropertyState == 1
        set iskeyword=@,47-57,_,192-255,@-@,+,-,.,(,),:
        let $nextKeywordIsPropertyState=2
        echo "ENTER key now also selects extended function and variable set"
    else
        set iskeyword=@,48-57,_,192-255
        let $nextKeywordIsPropertyState=0
        echo "ENTER key selects: Standard characters only"
    endif
endfunc
let $nextKeywordIsPropertyState=0
set iskeyword=@,48-57,_,192-255

let g:highlightword = 1
fu! ToggleHighlightWord()
   if g:highlightword == 0
      let g:highlightword = 1
      echo "Full word only highlighting"
   else
      let g:highlightword = 0
      echo "Partial word highlighting"
   endif
endfunc

let g:highlighting = 0
function! Highlighting()
  if g:highlightword == 1
     if g:highlighting == 1 && @/ =~ '^\\<'.expand('<cword>').'\\>$'
       let g:highlighting = 0
       return ":silent nohlsearch\<CR>"
     endif
  else
     if g:highlighting == 1 && @/ =~ '^'.expand('<cword>').'$'
       let g:highlighting = 0
       return ":silent nohlsearch\<CR>"
     endif
  endif

  if g:highlightword == 1
     let @/ = '\<'.expand('<cword>').'\>'
   else
     let @/ = expand('<cword>')
   endif
  let g:highlighting = 1
  return ":silent set hlsearch\<CR>yiw"
endfunction

function! EnableHighlighting()
   nnoremap <silent> <expr> <CR> Highlighting()
endfunction

function! DisableHighlighting()
   unmap <silent> <CR>
endfunction

call EnableHighlighting()
auto CmdwinEnter * call DisableHighlighting()
auto CmdwinLeave * call EnableHighlighting()

" Toggle line numbering
fu! ToggleNumbering()
    if $numberingState == 0
        let $numberingState=1
        set nu foldcolumn=4
        ShowMarksToggle
    else
        let $numberingState=0
        set nonu foldcolumn=0
        ShowMarksToggle
    endif
endfunc
let $numberingState=1

" Toggle fold visibility
fu! ToggleFold()
   if (&foldenable)
      set nofoldenable
      set foldcolumn=0
   else
      set foldenable
      set foldmethod=indent
      set foldnestmax=9
      let javaScript_fold=1         " JavaScript
      let perl_fold=1               " Perl
      let php_folding=1             " PHP
      let r_syntax_folding=1        " R
      let ruby_fold=1               " Ruby
      let sh_fold_enabled=1         " sh
      let vimsyn_folding='af'       " Vim script
      let xml_syntax_folding=1      " XML
      set foldcolumn=4
   endif
endfunc

" Toggle displaying of errors
fu! ToggleDisplayErrors()
    if g:display_error_state
        hi link postscrError Normal
        hi link postscrHexString Normal
        hi link htmlError Normal
        hi link shDerefWordError Normal
        hi! link Error Normal
    else
        hi link postscrError Error
        hi link postscrHexString postscrString
        hi link htmlError Error
        hi link shDerefWordError Error
        hi! link Error NONE
    endif
    let g:display_error_state = ! g:display_error_state
endfunc
let g:display_error_state = 1
call ToggleDisplayErrors()

fu! ToggleColorColumns()
   if w:display_color_columns
      let &colorcolumn=w:display_color_column_set
   else
      set colorcolumn=
   endif
    let w:display_color_columns = ! w:display_color_columns
endfunc
fu! ToggleColorColumnSet()
   if w:display_color_column_set == "58,118"
      let w:display_color_column_set = "58,67,118"
   elseif w:display_color_column_set == "58,67,118"
      let w:display_color_column_set = "58,76,118"
   elseif w:display_color_column_set == "58,76,118"
      let w:display_color_column_set = "58,85,118"
   elseif w:display_color_column_set == "58,85,118"
      let w:display_color_column_set = "58,94,118"
   elseif w:display_color_column_set == "58,94,118"
      let w:display_color_column_set = "58,103,118"
   elseif w:display_color_column_set == "58,103,118"
      let w:display_color_column_set = ""
   elseif w:display_color_column_set == ""
      let w:display_color_column_set = "58,118"
   endif
   let &colorcolumn=w:display_color_column_set
endfunc

nnoremap <silent> ,/ :call <SID>SearchMode()<CR>
function s:SearchMode()
  if !exists('s:searchmode') || s:searchmode == 0
    echo 'Search next: scroll hit to middle if not on same page'
    nnoremap <silent> n n:call <SID>MaybeMiddle()<CR>
    nnoremap <silent> N N:call <SID>MaybeMiddle()<CR>
    let s:searchmode = 1
  elseif s:searchmode == 1
    echo 'Search next: scroll hit to middle'
    nnoremap n nzz
    nnoremap N Nzz
    let s:searchmode = 2
  else
    echo 'Search next: normal'
    nunmap n
    nunmap N
    let s:searchmode = 0
  endif
endfunction

" If cursor is in first or last line of window, scroll to middle line.
function s:MaybeMiddle()
  if winline() == 1 || winline() == winheight(0)
    normal! zz
  endif
endfunction

fu! SetBufWinEnter()
   let w:display_color_columns = 0
   let &colorcolumn = ""

   if &filetype ==# 'sh'
      if ! exists('&w:display_color_column_set')
         let w:display_color_column_set = "58,118"
      endif

      let &colorcolumn=w:display_color_column_set
      let w:display_color_columns = 1
   endif
endfunc

auto BufWinEnter * call SetBufWinEnter()

map ,* yiw:match MyGroup /<c-r>"/<CR>

" Decrease fold level
map ,< zm
" Increase fold level
map ,> zr

" Function key mappings
" Highlighting
map <f1> :noh<cr>:match<cr>
map <S-f1> :noh<cr>:match<cr>:call RefreshEggHighlighting()<cr>
map <S-f1> :call ToggleDisplayErrors()<cr>
" Folds: f2=enabled/disabled, f3=open/close
map <f2> :call ToggleFold()<CR>
map <f3> zA
" Show version differences for a file (left: current, right: history)
" Use numeric + and numeric - to scroll through history
map <f4> :call ToggleVersDiff()<cr>
map <silent> <S-f4> :call EndVersDiff()<cr>
map <f6> :call ToggleKeywordIsPropertyState()<CR>
map <S-f6> :call ToggleHighlightWord()<CR>
map <f7> :cd %:h<CR>
map <f8> :call FontBigger()<CR>:echo "Font size: " . $currentFontSize<CR>
map <s-f8> :call FontSmaller()<CR>:echo "Font size: " . $currentFontSize<CR>
map <f9> :call ZoomWin()<CR>
map <f10> :call ToggleNumbering()<CR>
" Toggle color columns (to help user make alignment decisions)
map <f11> :call ToggleColorColumns()<CR>
" Change the set of color columns that are being used
map <S-f11> :call ToggleColorColumnSet()<CR>
" Save/Restore the session
map <f12> :mksession! $HOME/.vim/vimsession.vim<CR>
map <s-f12> :so $HOME/.vim/vimsession.vim<CR>

" ===== Miscellaneous =====
" Goto file under cursor
map ,g <C-W><C-F>

" Search for next log entry
map ,l /^\[[^]]*\]<CR>

" Search for BashG token
map ,k /%{[^}]*}%<cr>

" Read a template into the current buffer
map ,T :.-1r $VIM/template/
map ,t :r $VIM/template/

" Open Buffer Explorer: easily navigate between buffers
map ,x :BufExplorer<CR>

" Yank to end of line
map Y y$

" Replay macro a (Record a macro: qa ... q, then replay with <C-A>)
map <C-A> @a

" Move to the previous/next file
map <C-P> :N<cr>
map <C-N> :n<cr>

" ===== Copy, Delete, and Paste =====
" Move 'a to top
map ,a 'az<CR>
" Mark the end of a block
map ,e me
" Copy to the mark
map ,c "ay'e
" Copy and Remove content to the mark
map ,r "ay'ed'e
" Put copied content below cursor line
map ,p "ap
map ,v "ap
" Put coopied content above cursor line
map ,P "aP
map ,V "aP
" Remove JSON annotations
map ,J 1G!Gsed '/^ *\(\#\\|$\)/d'<CR>
map ,j 1G!Gsed '/^ *\(\#\\|$\)/d'\|jq --indent 3 -r .<CR>
map ,S 1G!Gsed '/^ *\(\#\\|$\)/d'\|jq --indent 3 -rS .<CR>
" Remove trailing spaces on save

" Resizing Windows
map <M-Left> <C-W><
map <M-Up> <C-W>+
map <M-Down> <C-W>-
map <M-Right> <C-W>>

" Split the current window, opening a new window in the direction indicated
map <C-S-Right> :vnew<CR>
map <C-S-Left> :se nosplitright<CR>:vnew<CR>:se splitright<CR>
map <C-S-Down> :se splitbelow<CR>:new<CR>
map <C-S-Up> :se nosplitbelow<CR>:new<CR>

" Move to a window in the direction indicated
map <C-Right> <c-w>l
map <C-Left> <c-w>h
map <C-Up> <c-w>k
map <C-Down> <c-w>j

" Rotate windows to the right
map <C-M-Right> <c-w>r

" Update current buffer with any changes that are on disk, but not in the buffer yet
map <C-U> M:e!<cr>

" Terminate vim without writing
map <C-T> :qa!<cr>

" Terminate vim, but save all files first
map <C-M-T> :xa!<cr>

" Show the vim syntax type under the cursor
function! SynStack()
    if !exists('*synstack')
        return
    endif
    echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endfunc
map <s-f10> :call SynStack()<CR>

" Vim diffing
let $diffWhiteState=1
fu! ToggleDiffWhite()
    if $diffWhiteState == 0
        set diffopt-=iwhite
        let $diffWhiteState=1
    else
        set diffopt+=iwhite
        let $diffWhiteState=0
    endif
endfunc

fu! ToggleVersDiff()
   if $versdiffState == 0
      let $versdiffState=1
      nmap <silent> - :VersDiff -<cr>
      nmap <silent> + :VersDiff +<cr>
      nmap <silent> <kMinus> :VersDiff -<cr>
      nmap <silent> <kPlus> :VersDiff +<cr>
      VersDiff -
   else
      let $versdiffState=0
      unmap <silent> -
      unmap <silent> +
      unmap <silent> <kMinus>
      unmap <silent> <kPlus>
      VersDiff -c
   endif
endfunc
fu! EndVersDiff()
   Purge 0
   w!
endfunc
let $versdiffState=0

fu! DiffSetup()
    syntax off
    auto GUIEnter * simalt ~x

    set diffopt=filler,context:9999
    set cursorbind scrollbind cursorline
    map <f5> :diffupdate<CR>
    map <right> :diffget<CR>
    map <left> :diffput<CR>
    map <down> ]cz.<c-w><c-w><c-w><c-w>
    map <up> [cz.<c-w><c-w><c-w><c-w>
    map <s-down> do
    map <s-up> dp
    map <m-down> <c-w>wyy<c-w>wPjddk
    map <m-s-down> <c-w>wyy<c-w>wPj
    map u :u<cr>:dif<cr>
    map U :red<cr>:dif<cr>
    let $currentFontSize=8
    call FontBigger()
    hi clear CursorLine
    hi CursorLine cterm=underline
endfunc

fu! DiffThis()
    " Move to the left-most window
    exe "normal \<C-w>t"
    call DiffSetup()
    diffthis
    " Move to the right-most window
    exe "normal \<C-w>b"
    call DiffSetup()
    diffthis
    " Move back to the left-most window
    exe "normal \<C-w>b1G]c"
endfunc
map ,d :call DiffThis()<CR>
cnoreabbrev D DirDiff
map ,i :call ToggleDiffWhite()<CR>
map ,n /\(\[\(\n\s*#.*\)*\n\s*\]\\|null\\|""\)<CR>
map ,B ^i# <ESC>$a #<ESC>O#<ESC>:se nowrap<CR>125a#<ESC>jhlklDyyjp:se wrap<CR>

let @R='^\(\(\s*\(#.*\|\s*echo.*\)\)\@!..*\)$'
map ,R /<C-R>R<CR>

auto BufNewFile,BufRead *.conf set filetype=conf
auto BufNewFile,BufRead * if &syntax == '' | set syntax=sh | endif
auto VimEnter * if &diff | let $wrapState=0 | call ToggleWrap() | endif

if &diff
    call DiffSetup()
else
   auto BufNewFile,BufRead * call RefreshEggHighlighting()
endif

auto BufEnter * let &titlestring = expand("%:t")

" DO NOT MAKE CHANGES TO THIS FILE =================================
" Place local changes in $HOME/.vim/plugin/rc.vim
