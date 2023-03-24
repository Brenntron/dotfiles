set nocompatible              " be iMproved, required
filetype off                  " required
set syntax=on
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
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'wincent/ferret'
Plug 'jeetsukumaran/vim-buffergator'
Plug 'gilsondev/searchtasks.vim'
Plug 'chrisbra/Colorizer'
Plug 'tpope/vim-dispatch'
Plug 'dense-analysis/ale'
Plug 'dbakker/vim-projectroot'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-haml'

" Kitty Support
Plug 'knubie/vim-kitty-navigator', {'do': 'cp ./*.py ~/.config/kitty/'}
Plug 'fladson/vim-kitty'

" Generic Programming Support
Plug 'ludovicchabant/vim-gutentags'
Plug 'skywind3000/gutentags_plus'
Plug 'honza/vim-snippets'
Plug 'Townk/vim-autoclose'
Plug 'tomtom/tcomment_vim'
Plug 'tobyS/vmustache'
Plug 'janko-m/vim-test'
Plug 'maksimr/vim-jsbeautify'
Plug 'ntpeters/vim-better-whitespace'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

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
" Solargraphy support'
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }

" JavaScript Support
Plug 'flowtype/vim-flow'

" Coffeescript Support
Plug 'kchmck/vim-coffee-script'

" Yaml Support
Plug 'stephpy/vim-yaml'
Plug 'pedrohdz/vim-yaml-folds'

" Theme / Interface
Plug 'vim-scripts/AnsiEsc.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sjl/badwolf'
Plug 'tomasr/molokai'
Plug 'morhetz/gruvbox'
Plug 'junegunn/limelight.vim'
Plug 'mkarmona/colorsbox'
Plug 'romainl/Apprentice'
Plug 'Lokaltog/vim-distinguished'
Plug 'chriskempson/base16-vim'
Plug 'w0ng/vim-hybrid'
Plug 'AlessandroYorba/Sierra'
Plug 'ajh17/Spacegray.vim'
Plug 'atelierbram/Base2Tone-vim'
Plug 'colepeters/spacemacs-theme.vim'
Plug 'liuchengxu/space-vim-dark'
Plug 'dracula/vim', { 'as': 'dracula' }


call plug#end()

filetype plugin on
filetype plugin indent on

syntax on
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
autocmd BufNewFile,BufRead *.ts set filetype=javascript
autocmd BufNewFile,BufRead *.ts set syntax=javascript
au BufRead,BufNewFile *.vim setfiletype vim
au BufRead,BufNewFile *.scss set filetype=scss
au BufRead,BufNewFile *.haml set filetype=haml
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
autocmd BufEnter * :syntax sync fromstart

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

let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_enabled = 1
let g:ale_fix_on_save = 0
let g:ale_keep_list_window_open = 1
let g:ale_lint_on_text_changed = 1
let g:ale_linter_explicit = 1
let g:ale_open_list = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_sign_column_always = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '?'
let g:ale_statusline_format = ['X %d', '? %d', '']

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
" Required for operations modifying multiple buffers like rename.
set hidden

let g:LanguageClient_serverCommands = {
    \ 'rust': ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
    \ 'javascript': ['/usr/local/bin/javascript-typescript-stdio'],
    \ 'javascript.jsx': ['tcp://127.0.0.1:2089'],
    \ 'python': ['/usr/local/bin/pyls'],
    \ 'ruby': ['~/.rbenv/shims/solargraph', 'stdio'],
    \ }

" note that if you are using Plug mapping you should not use `noremap` mappings.
nmap <F5> <Plug>(lcn-menu)
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
inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"

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

" coc settings
set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Remap keys for coc gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
command! -nargs=0 Prettier :call CocAction('runCommand',. 'prettier.formatFile')

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
set statusline+=%{gutentags#statusline()}

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

" gutentags config
let g:gutentags_modules = ['ctags', 'gtags_cscope']
let g:gutentags_cache_dir = expand('~/.gutentags_cache')
let g:gutentags_exclude_filetypes = ['gitcommit', 'gitconfig', 'gitrebase', 'gitsendemail', 'git', 'man']
let g:gutentags_ctags_exclude = [
\  '*-lock.json', '*.bak', '*.bin','*.bmp', '*.cache', '*.class', '*.csproj',
\  '*.csproj.user', '*.dll', '*.doc', '*.docx', '*.exe', '*.flac', '*.gif',
\  '*.git', '*.hg', '*.ico', '*.jpg', '*.lock', '*.min.*', '*.mp3', '*.ogg',
\  '*.pdb', '*.pdf', '*.plist', '*.png', '*.ppt', '*.pptx', '*.pyc', '*.rar',
\  '*.sln', '*.svg', '*.svn', '*.swo', '*.swp', '*.tar', '*.tar.bz2',
\  '*.tar.gz', '*.tar.xz', '*.tmp', '*.vscode', '*.xls', '*.zip', '*.zip',
\  '.DS_Store', 'BOWER_COMPONENTS', 'bin', 'build', 'cache', 'dist', 'extras',
\  'node_modules', 'vendor'
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

" CoC Options
let g:coc_global_extensions = ['coc-json', 'coc-git', 'coc-css', 'coc-solargraph', 'coc-html', 'coc-prettier']
let g:coc_node_path = '$HOME/.asdf/shims/node'

" Colorscheme
colorscheme dracula
hi LineNr ctermbg=NONE guibg=NONE
hi Comment cterm=italic
syntax enable
