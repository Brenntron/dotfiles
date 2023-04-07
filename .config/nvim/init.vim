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

" Git Support
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Kitty Support
Plug 'fladson/vim-kitty'
Plug 'knubie/vim-kitty-navigator', {'do': 'cp ./*.py ~/.config/kitty/'}

" Markdown / Writing
Plug 'reedes/vim-pencil'

" Utility
Plug 'chrisbra/Colorizer'
Plug 'cuducos/yaml.nvim'
Plug 'janko-m/vim-test'
Plug 'ntpeters/vim-better-whitespace'
Plug 'numToStr/Comment.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.x' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-refactor'
Plug 'petertriho/nvim-scrollbar'
Plug 'schickling/vim-bufonly'
Plug 'sheerun/vim-polyglot'
Plug 'ThePrimeagen/refactoring.nvim'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-vinegar'
Plug 'wesQ3/vim-windowswap'

" Language Server Protocol Support
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'williamboman/mason.nvim', { 'do': ':MasonUpdate' }

" Diagnostics, Linting, and Formatting
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'jay-babu/mason-null-ls.nvim'

" Autocompletion
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/nvim-cmp'
Plug 'windwp/nvim-autopairs'
Plug 'windwp/nvim-ts-autotag'
Plug 'RRethy/nvim-treesitter-endwise'

" LSP bundle
Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v2.x'}

" Theme / Interface
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'powerman/vim-plugin-AnsiEsc'
Plug 'nvim-lualine/lualine.nvim'

call plug#end()

" Set runtime path
set runtimepath^=~/.config/nvim/

" Customisations
" colorscheme
colorscheme dracula
hi LineNr ctermbg=NONE guibg=NONE
hi Comment cterm=italic
syntax enable
filetype plugin on

" Remove whitespace
let g:better_whitespace_enabled=1

" Status bar
set laststatus=2
set cmdheight=1
set noshowmode

set modelines=0
set number rnu
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
  au BufNewFile,BufRead *.jsx set filetype=javascript.jsx
  au BufNewFile,BufRead *.coffee set filetype=coffee
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

" Rendering
set ttyfast

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

" RipGrep config
nmap <Leader>s :Rg <C-R><C-W>

" (Neo)Vim's native statusline support.
set statusline+=%{FugitiveStatusline()}

" Find files using Telescope command-line sugar.
nnoremap ; <cmd>Telescope buffers<cr>
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>s <cmd>Telescope live_grep<cr>
nnoremap <leader>r <cmd>Telescope help_tags<cr>

" nvim-tree keybindings
nnoremap <Leader>e <cmd>NvimTreeToggle<cr>

" Keybindings
ino <silent><expr> <Esc>   pumvisible() ? "\<C-e><Esc>" : "\<Esc>"
ino <silent><expr> <C-c>   pumvisible() ? "\<C-e><C-c>" : "\<C-c>"
ino <silent><expr> <BS>    pumvisible() ? "\<C-e><BS>"  : "\<BS>"
ino <silent><expr> <CR>    pumvisible() ? (complete_info().selected == -1 ? "\<C-e><CR>" : "\<C-y>") : "\<CR>"
ino <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
ino <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<BS>"

" Run the config for lua plugins
lua require("config")
