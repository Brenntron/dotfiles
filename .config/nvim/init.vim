set nocompatible              " be iMproved, required
filetype off                  " required
set nowrap

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" vim-plug
call plug#begin('~/.vim/plugged')

" Elixir Support
Plug 'avdgaag/vim-phoenix'
Plug 'brendalf/mix.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'tpope/vim-endwise'

" Git Support
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Kitty Support
Plug 'fladson/vim-kitty'
Plug 'knubie/vim-kitty-navigator', {'do': 'cp ./*.py ~/.config/kitty/'}

" Markdown / Writting
Plug 'reedes/vim-pencil'

" Utility
Plug 'chrisbra/Colorizer'
Plug 'janko-m/vim-test'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'ludovicchabant/vim-gutentags'
Plug 'majutsushi/tagbar'
Plug 'ntpeters/vim-better-whitespace'
Plug 'numToStr/Comment.nvim'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'petertriho/nvim-scrollbar'
Plug 'schickling/vim-bufonly'
Plug 'sheerun/vim-polyglot'
Plug 'skywind3000/gutentags_plus'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-vinegar'
Plug 'wesQ3/vim-windowswap'

" Theme / Interface
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'powerman/vim-plugin-AnsiEsc'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

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
" Copy and paste to clipboard
set clipboard^=unnamed,unnamedplus

let g:loaded_perl_provider = 0

syn match javaScriptCommentSkip "^[ \t]*\*\($\|[ \t]\+\)"
syn region javaScriptComment start="/\*" end="\*/" contains=@Spell,javaScriptCommentTodo
syn match javaScriptSpecial "\\\d\d\d\|\\."
augroup FiletypeGroup
  au!
  au BufNewFile,BufRead *.js.es6 set filetype=javascript
  au BufNewFile,BufRead *.es6 set filetype=javascript
  au BufNewFile,BufRead *.js.erb set filetype=javascript
  au BufNewFile,BufRead *.ts set filetype=javascript
  au BufNewFile,BufRead *.jsx set filetype=javascript.jsx
  au BufNewFile,BufRead *.vim setfiletype vim
  au BufNewFile,BufRead *.scss set filetype=scss
  au BufNewFile,BufRead *.haml set filetype=haml
  au BufNewFile,BufRead *.yml set filetype=yaml
  au BufNewFile,BufRead *.md,*.markdown setlocal filetype=ghmarkdown
augroup END
autocmd BufWritePre * :%s/\s\+$//e
syn region javaScriptStringD	start=+"+ skip=+\\\\\|\\"+ end=+"\|$+	contains=javaScriptSpecial,@htmlPreproc
syn region javaScriptStringS	start=+'+ skip=+\\\\\|\\'+ end=+'\|$+	contains=javaScriptSpecial,@htmlPreproc
syn match javaScriptSpecialCharacter "'\\.'"
syn match javaScriptNumber	"-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"
autocmd FileType json syntax match Comment +\/\/.\+$+
autocmd BufEnter * :syntax sync fromstart

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

" Rendering
set ttyfast

" Status bar
set laststatus=2

" Show mode and command
set showmode
set showcmd

let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
let g:languagetool_jar  = '/opt/languagetool/languagetool-commandline.jar'

" Vim-pencil Configuration
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
  autocmd FileType text         call pencil#init()
augroup END

" Close popup by <Space>.
inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"

" vim-test Setup

nmap <silent> t<C-n> :TestNearest<CR>
nmap <silent> t<C-f> :TestFile<CR>
nmap <silent> t<C-s> :TestSuite<CR>
nmap <silent> t<C-l> :TestLast<CR>
nmap <silent> t<C-g> :TestVisit<CR>

" ctag config
nmap <Leader>j :tag <C-R><C-W>

" RipGrep config
nmap <Leader>s :Rg <C-R><C-W>

" language client server

let g:LanguageClient_serverCommands = {
    \ 'rust': ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
    \ 'javascript': ['/usr/local/bin/javascript-typescript-stdio'],
    \ 'javascript.jsx': ['tcp://127.0.0.1:2089'],
    \ 'python': ['/usr/local/bin/pyls'],
    \ 'ruby': ['~/.rbenv/shims/solargraph', 'stdio'],
    \ }

" fzf config
nmap ; :Buffers<CR>
nmap <Leader>f :Files<CR>
nmap <Leader>r :Tags<CR>

" This is the default option:
"   - Preview window on the right with 50% width
"   - CTRL-/ will toggle preview window.
" - Note that this array is passed as arguments to fzf#vim#with_preview function.
" - To learn more about preview window options, see `--preview-window` section of `man fzf`.
let g:fzf_preview_window = ['right,50%', 'ctrl-/']

let g:fzf_tags_command = 'ctags -R'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Use Rg with fzf
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%', '?'),
  \   <bang>0)

" gutentags config
let g:gutentags_ctags_executable = '/usr/local/bin/ctags'
let g:gutentags_modules = ['ctags']
let g:gutentags_cache_dir = '~/.gutentags_cache'
let g:gutentags_project_root = ['.git']
let g:gutentags_exclude_filetypes = ['gitcommit', 'gitconfig', 'gitrebase', 'gitsendemail', 'git', 'man']
let g:gutentags_ctags_exclude = [
\  '*-lock.json', '*.bak', '*.bin','*.bmp', '*.cache', '*.class', '*.csproj',
\  '*.csproj.user', '*.dll', '*.doc', '*.docx', '*.exe', '*.flac', '*.gif',
\  '*.git', '*.hg', '*.ico', '*.jpg', '*.lock', '*.min.*', '*.mp3', '*.ogg',
\  '*.pdb', '*.pdf', '*.plist', '*.png', '*.ppt', '*.pptx', '*.pyc', '*.rar',
\  '*.sln', '*.svg', '*.svn', '*.swo', '*.swp', '*.tar', '*.tar.bz2',
\  '*.tar.gz', '*.tar.xz', '*.tmp', '*.vscode', '*.xls', '*.zip', '*.zip',
\  '.DS_Store', 'BOWER_COMPONENTS', 'bin', 'build', 'cache', 'dist', 'extras',
\  'node_modules', 'vendor', '*.yml'
\]
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_generate_on_empty_buffer = 0
let g:gutentags_ctags_extra_args = [
      \ '--tag-relative=yes',
      \ '--fields=+ailmnS',
      \ ]

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

" Tagbar setup
nmap <F8> :TagbarToggle<CR>

" Colorscheme
colorscheme dracula
hi LineNr ctermbg=NONE guibg=NONE
hi Comment cterm=italic
syntax enable
filetype plugin on

" Airline
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tabline#enabled = 1

let g:airline_powerline_fonts = 1

let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'

" (Neo)Vim's native statusline support.
set statusline+=%{gutentags#statusline()}
set statusline+=%{FugitiveStatusline()}

" Run the config for lua plugins
lua require("config")
