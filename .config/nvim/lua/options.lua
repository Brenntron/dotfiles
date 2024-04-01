vim.opt.backup = false -- creates a backup file
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.cmdheight = 1 -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0 -- so that `` is visible in markdown files
vim.opt.cursorline = true -- highlight the current line
vim.opt.fileencoding = "utf-8" -- the encoding written to a file
vim.opt.fillchars.eob = " " -- show empty lines at the end of a buffer as ` ` {default `~`}
vim.opt.fillchars:append {
  stl = " ",
}
vim.opt.formatoptions:remove { "c", "r", "o" } -- this is a sequence of letters which describes how automatic formatting is to be done
vim.opt.guifont = "monospace:h17" -- the font used in graphical neovim applications
vim.opt.hlsearch = true -- highlight all matches on previous search pattern
vim.opt.ignorecase = true -- ignore case in search patterns
vim.opt.laststatus = 3 -- only the last window will always have a status line
vim.opt.linebreak = true
vim.opt.mouse = "a" -- allow the mouse to be used in neovim
vim.opt.number = true -- set numbered lines
vim.opt.numberwidth = 4 -- minimal number of columns to use for the line number {default 4}
vim.opt.pumblend = 10
vim.opt.pumheight = 10 -- pop up menu height
vim.opt.relativenumber = true -- set relative numbered lines
vim.opt.ruler = true -- hide the line and column number of the cursor position
vim.opt.scrolloff = 0 -- minimal number of screen lines to keep above and below the cursor
vim.opt.shortmess:append "c" -- hide all the completion messages, e.g. "-- XXX completion (YYY)", "match 1 of 2", "The only match", "Pattern not found"
vim.opt.showcmd = false -- hide (partial) command in the last line of the screen (for performance)
vim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 1 -- always show tabs
vim.opt.sidescrolloff = 0 -- minimal number of screen columns to keep to the left and right of the cursor if wrap is `false`
vim.opt.signcolumn = "yes" -- always show the sign column, otherwise it would shift the text each time
vim.opt.smartcase = true -- smart case
vim.opt.splitbelow = true -- force all horizontal splits to go below current window
vim.opt.splitright = true -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false -- creates a swapfile
vim.opt.termguicolors = true -- set term gui colors (most terminals support this)
vim.opt.timeout = true
vim.opt.timeoutlen = 1000 -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true  -- enable persistent undo
vim.opt.updatetime = 100 -- faster completion (4000ms default)
vim.opt.wrap = false -- display lines as one long line
vim.opt.writebackup = false  -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.eol = true

-- Tab settings
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.tabstop = 2 -- insert 2 spaces for a tab
vim.opt.softtabstop = 2 -- insert 2 spaces for a tab

-- Indent settings
vim.opt.shiftwidth = 2 -- the number of spaces inserted for each indentation
vim.opt.smartindent = true -- make indenting smarter again

vim.cmd "set whichwrap+=<,>,[,],h,l" -- keys allowed to move to the previous/next line when the beginning/end of line is reached
vim.cmd [[set iskeyword+=-]] -- treats words with `-` as single words

-- Globals
vim.g.lazygit_config_file_path = {} -- table of custom config file paths
vim.g.lazygit_floating_window_border_chars = {'╭','─', '╮', '│', '╯','─', '╰', '│'} -- customize lazygit popup window border characters
vim.g.lazygit_floating_window_scaling_factor = 0.9 -- scaling factor for floating window
vim.g.lazygit_floating_window_use_plenary = 1 -- use plenary.nvim to manage floating window if available
vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window
vim.g.lazygit_use_custom_config_file_path = 0 -- config file path is evaluated if this value is 1
vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed
vim.g.loaded_perl_provider = 0 -- Disable Perl provider
vim.g.mapleader = " "

-- add filetypes
vim.filetype.add { extension = { coffee = "coffee" }, { config = "conf" } }

-- netrw
vim.g.netrw_banner = 0
vim.g.netrw_dirhistcnt = 2
vim.g.netrw_dirhistmax = 10
vim.g.netrw_mouse = 2
