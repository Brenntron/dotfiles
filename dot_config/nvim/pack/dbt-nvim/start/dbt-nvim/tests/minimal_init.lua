-- Minimal init for running dbt-nvim specs headlessly with plenary.busted.
-- Usage: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"
local site = vim.fn.expand("~/.local/share/nvim/site/pack/core/opt")
vim.opt.runtimepath:append(site .. "/plenary.nvim")
vim.opt.runtimepath:append(site .. "/snacks.nvim")

-- Add this plugin's lua/ to the package path.
local root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:p"), ":h:h")
vim.opt.runtimepath:append(root)

require("plenary.busted")
