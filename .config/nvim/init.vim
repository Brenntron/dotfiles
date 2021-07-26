set nocompatible              " be iMproved, required
filetype off                  " required
syntax on
set nowrap
set encoding=utf8

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" vim-plug
call plug#begin('~/.vim/plugged')

" Utility
Plug 'tpope/vim-vinegar'
Plug 'majutsushi/tagbar'
Plug 'sheerun/vim-polyglot'
Plug 'schickling/vim-bufonly'
Plug 'wesQ3/vim-windowswap'
Plug 'SirVer/ultisnips'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'wincent/ferret'
Plug 'benmills/vimux'
Plug 'jeetsukumaran/vim-buffergator'
Plug 'gilsondev/searchtasks.vim'
Plug 'chrisbra/Colorizer'
Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}
Plug 'tpope/vim-dispatch'
Plug 'dense-analysis/ale'
Plug 'dbakker/vim-projectroot'
Plug 'scrooloose/nerdtree'

" Generic Programming Support
Plug 'ludovicchabant/vim-gutentags'
Plug 'honza/vim-snippets'
Plug 'Townk/vim-autoclose'
Plug 'tomtom/tcomment_vim'
Plug 'tobyS/vmustache'
Plug 'janko-m/vim-test'
Plug 'maksimr/vim-jsbeautify'
Plug 'christoomey/vim-tmux-navigator'
Plug 'ntpeters/vim-better-whitespace'

" Markdown / Writting
Plug 'reedes/vim-pencil'
Plug 'tpope/vim-markdown'
Plug 'jtratner/vim-flavored-markdown'
Plug 'dpelle/vim-LanguageTool'

" Git Support
Plug 'kablamo/vim-git-log'
Plug 'gregsexton/gitv'
Plug 'tpope/vim-fugitive'
Plug 'jaxbot/github-issues.vim'
Plug 'airblade/vim-gitgutter'

" Elixir Support
Plug 'elixir-lang/vim-elixir'
Plug 'avdgaag/vim-phoenix'
Plug 'mmorearty/elixir-ctags'
Plug 'mattreduce/vim-mix'
Plug 'mhinz/vim-mix-format'
Plug 'frost/vim-eh-docs'
Plug 'slashmili/alchemist.vim'
Plug 'tpope/vim-endwise'
Plug 'jadercorrea/elixir_generator.vim'

" Ruby Support
Plug 'vim-ruby/vim-ruby'
Plug 'hackhowtofaq/vim-solargraph'
Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
  \ }

" Freemarker Support
Plug 'andreshazard/vim-freemarker'

" TypeScript Support
Plug 'leafgarland/typescript-vim'

" JavaScript Support
Plug 'flowtype/vim-flow'

" Vue.js
Plug 'posva/vim-vue'

" Theme / Interface
Plug 'vim-scripts/AnsiEsc.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sjl/badwolf'
Plug 'tomasr/molokai'
Plug 'morhetz/gruvbox'
Plug 'zenorocha/dracula-theme', {'rtp': 'vim/'}
Plug 'junegunn/limelight.vim'
Plug 'mkarmona/colorsbox'
Plug 'romainl/Apprentice'
Plug 'Lokaltog/vim-distinguished'
Plug 'chriskempson/base16-vim'
Plug 'w0ng/vim-hybrid'
Plug 'AlessandroYorba/Sierra'
Plug 'daylerees/colour-schemes'
Plug 'ajh17/Spacegray.vim'
Plug 'atelierbram/Base2Tone-vim'
Plug 'colepeters/spacemacs-theme.vim'
Plug 'flazz/vim-colorschemes'
Plug 'rafi/awesome-vim-colorschemes'
Plug 'exitface/synthwave.vim'
Plug 'liuchengxu/space-vim-dark'

call plug#end()

filetype plugin indent on
set omnifunc=syntaxcomplete#Complete


" OSX stupid backspace fix
set backspace=indent,eol,start

"" Customisations
""
let g:better_whitespace_enabled=1
set modelines=0
set nu rnu
set ruler
set visualbell
set wrap
set textwidth=119
set formatoptions=tcqrn1
set tabstop=2
set shiftwidth=2
set softtabstop=2
set smarttab
set expandtab
set noshiftround
let g:node_host_prog = '/Users/Brenntron/.asdf/installs/nodejs/16.3.0/bin/npm'

syn match javaScriptCommentSkip "^[ \t]*\*\($\|[ \t]\+\)"
syn region javaScriptComment start="/\*" end="\*/" contains=@Spell,javaScriptCommentTodo
syn match javaScriptSpecial "\\\d\d\d\|\\."
autocmd BufNewFile,BufRead *.js.es6 set filetype=javascript
autocmd BufNewFile,BufRead *.js.es6 set syntax=javascript
autocmd BufNewFile,BufRead *.js.erb set filetype=javascript
autocmd BufNewFile,BufRead *.js.erb set syntax=javascript
autocmd BufNewFile,BufRead *.js.coffee set filetype=javascript
autocmd BufNewFile,BufRead *.js.coffee set syntax=javascript
autocmd BufNewFile,BufRead *.ts set filetype=javascript
autocmd BufNewFile,BufRead *.ts set syntax=javascript
autocmd BufWritePre * :%s/\s\+$//e
augroup FiletypeGroup
  autocmd!
  au BufNewFile,BufRead *.es6 set filetype=javascript
augroup END
syn region javaScriptStringD	start=+"+ skip=+\\\\\|\\"+ end=+"\|$+	contains=javaScriptSpecial,@htmlPreproc
syn region javaScriptStringS	start=+'+ skip=+\\\\\|\\'+ end=+'\|$+	contains=javaScriptSpecial,@htmlPreproc
syn match javaScriptSpecialCharacter "'\\.'"
syn match javaScriptNumber	"-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"
autocmd FileType json syntax match Comment +\/\/.\+$+

" Ale Configuration
let g:ale_linter_aliases = {'es6': ['javascript'], 'jsx': ['css', 'javascript']}

let g:ale_linters = {
\  'coffeescript': ['coffeelint'],
\  'javascript': ['eslint', 'prettier'],
\  'typescript': ['tslint'],
\  'es6': ['eslint'],
\  'scss': ['stylelint'],
\  'ruby': ['rubocop'],
\  'jsx': ['stylelint','javascript']
\}

let g:ale_fixers = {
\  '*': ['remove_trailing_lines', 'trim_whitespace'],
\  'javascript': ['eslint', 'prettier'],
\  'typescript': ['tslint'],
\  'es6': ['eslint'],
\  'scss': ['stylelint', 'prettier'],
\  'css': ['stylelint', 'prettier'],
\  'ruby': ['rubocop']
\}

let g:ale_enabled = 1
let g:ale_lint_on_text_changed = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_sign_column_always = 1
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 1
let g:ale_fix_on_save = 1
let g:ale_linter_explicit = 1
let g:ale_sign_error = 'X'
let g:ale_sign_warning = '?'
let g:ale_statusline_format = ['X %d', '? %d', '']
let g:ale_echo_msg_format = '%linter% says %s'
let g:ale_elixir_elixir_ls_release = '/Users/Brenntron/code/elixir_ls/rel'

" Airline
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#coc#enabeld = 1

let g:airline_powerline_fonts = 1

let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'

let g:airline_section_error = '%{airline#util#wrap(airline#extensions#coc#get_error(),0)}'
let g:airline_section_warning = '%{airline#util#wrap(airline#extensions#coc#get_warning(),0)}'

let g:airline#extensions#coc#error_symbol = 'Error:'
let g:airline#extensions#ale#error_symbol = 'E:'
let g:airline#extensions#ale#warning_symbol = 'W:'

" language client server
let g:LanguageClient_serverCommands = {
  \ 'ruby': ['tcp://localhost:7658']
  \ }
let g:LanguageClient_autoStop = 0

" vim-vinegar settings
let g:netrw_list_hide = '\(^\|\s\s\)\zs\.\S\+'

set eol

" search config
set hlsearch
set ignorecase
set smartcase
set incsearch

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start
set matchpairs+=<:> " use % to jump between pairs
runtime! macros/matchit.vim

" Allow hidden buffers

set hidden

" Rendering
set ttyfast

" Status bar
set laststatus=2

" Last line
set showmode
set showcmd

set path=$PWD/**

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" vim-test bindings
"nmap <silent> t<C-n> :TestNearest<CR> " t Ctrl+n
"nmap <silent> t<C-f> :TestFile<CR>    " t Ctrl+f
"nmap <silent> t<C-s> :TestSuite<CR>   " t Ctrl+s
"nmap <silent> t<C-l> :TestLast<CR>    " t Ctrl+l
"nmap <silent> t<C-g> :TestVisit<CR>   " t Ctrl+g

" Colorscheme
color space-vim-dark
set termguicolors
hi LineNr ctermbg=NONE guibg=NONE
hi Comment cterm=italic

" Markdown Syntax Support
augroup markdown
    au!
    au BufNewFile,BufRead *.md,*.markdown setlocal filetype=ghmarkdown
augroup END

let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
let g:languagetool_jar  = '/opt/languagetool/languagetool-commandline.jar'

" Vim-pencil Configuration
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
  autocmd FileType text         call pencil#init()
augroup END

" JSX Syntax support
augroup FiletypeGroup
    autocmd!
    au BufNewFile,BufRead *.jsx set filetype=javascript.jsx
augroup END

" Vim-UtilSnips Configuration
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
let g:UltiSnipsEditSplit="vertical" " If you want :UltiSnipsEdit to split your window.

function! s:my_cr_function()
  return (pumvisible() ? "\<C-y>" : "" ) . "\<CR>"
  " For no inserting <CR> key.
  "return pumvisible() ? "\<C-y>" : "\<CR>"
endfunction

" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"

" AutoComplPop like behavior.

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType ruby setlocal omnifunc=LanguageClient#complete

" Elixir Tagbar Configuration
let g:tagbar_type_elixir = {
    \ 'ctagstype' : 'elixir',
    \ 'kinds' : [
        \ 'f:functions',
        \ 'functions:functions',
        \ 'c:callbacks',
        \ 'd:delegates',
        \ 'e:exceptions',
        \ 'i:implementations',
        \ 'a:macros',
        \ 'o:operators',
        \ 'm:modules',
        \ 'p:protocols',
        \ 'r:records',
        \ 't:tests'
    \ ]
    \ }

" Elixir Setup
let g:mix_format_on_save =1
let g:mix_format_options = '--check-equivalent'
let g:mix_format_silent_errors = 1

nmap <silent> t<C-n> :TestNearest<CR>
nmap <silent> t<C-f> :TestFile<CR>
nmap <silent> t<C-s> :TestSuite<CR>
nmap <silent> t<C-l> :TestLast<CR>
nmap <silent> t<C-g> :TestVisit<CR>

" ctag config
nmap <Leader>j :tag <C-R><C-W>

" RipGrep config
nmap <Leader>s :Rg <C-R><C-W>

" Remap keys for coc gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

command! -nargs=0 Prettier :call CocAction('runCommand',. 'prettier.formatFile')

" fzf config
nmap ; :Buffers<CR>
nmap <Leader>f :Files<CR>
nmap <Leader>r :Tags<CR>

" Override Rg commands to search inside git repo
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
    \ "rg --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>),
    \ 1,
    \ {'dir': FugitiveWorkTree()},
    \ <bang>0
  \ )

let g:fzf_tags_command = 'ctags -R'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

let g:gutentags_cache_dir = expand('~/.gutentags_cache')
let g:gutentags_exclude_filetypes = ['gitcommit', 'gitconfig', 'gitrebase', 'gitsendemail', 'git']
let g:gutentags_ctags_exclude = [
\  '*.git', '*.svn', '*.hg',
\  'cache', 'build', 'dist', 'bin', 'node_modules', 'bower_components',
\  '*-lock.json',  '*.lock',
\  '*.min.*',
\  '*.bak',
\  '*.zip',
\  '*.pyc',
\  '*.class',
\  '*.sln',
\  '*.csproj', '*.csproj.user',
\  '*.tmp',
\  '*.cache',
\  '*.vscode',
\  '*.pdb',
\  '*.exe', '*.dll', '*.bin',
\  '*.mp3', '*.ogg', '*.flac',
\  '*.swp', '*.swo',
\  '.DS_Store', '*.plist',
\  '*.bmp', '*.gif', '*.ico', '*.jpg', '*.png', '*.svg',
\  '*.rar', '*.zip', '*.tar', '*.tar.gz', '*.tar.xz', '*.tar.bz2',
\  '*.pdf', '*.doc', '*.docx', '*.ppt', '*.pptx', '*.xls',
\]

" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" Use Rg with fzf
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)
