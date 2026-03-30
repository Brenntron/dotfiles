-- Neovim options (loaded before plugins)

local opt = vim.opt

-- General
opt.autowrite = true
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.fillchars = { foldopen = "▾", foldclose = "▸", fold = " ", foldsep = " ", diff = "╱", eob = " " }
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.formatoptions = "jcroqlnt"
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"
opt.ignorecase = true
opt.inccommand = "nosplit"
opt.jumpoptions = "view"
opt.laststatus = 3
opt.linebreak = true
opt.list = true
opt.listchars = { tab = "> ", trail = " ", nbsp = "+" }
opt.mouse = "a"
opt.number = true
opt.pumblend = 10
opt.pumheight = 10
opt.relativenumber = true
opt.ruler = false
opt.scrolloff = 4
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true
opt.shiftwidth = 2
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.smoothscroll = true
opt.spelllang = { "en" }
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.tabstop = 2
opt.termguicolors = true
opt.timeoutlen = 300
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200
opt.virtualedit = "block"
opt.wildmode = "longest:full,full"
opt.winminwidth = 5
opt.wrap = false

-- Globals
vim.g.autoformat = false
vim.g.snacks_animate = true
vim.g.markdown_recommended_style = 0

-- Filetype additions
vim.filetype.add({
  extension = {
    avanterules = "markdown",
  },
  filename = {
    ["%.sqlfluff.*"] = "cfg",
  },
})

-- Python host (asdf/mise)
local python_path = vim.fn.trim(vim.fn.system("which python3"))
if vim.v.shell_error == 0 and python_path ~= "" then
  vim.g.python3_host_prog = python_path
end
