-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Change picker
vim.g.lazyvim_picker = "telescope"

-- auto format
vim.g.autoformat = false

-- listchars
vim.opt.listchars = {
  tab = "> ",
  trail = " ",
  nbsp = "+",
}

-- filetype settings
vim.filetype.add({
  extension = {
    avanterules = 'markdown'
  }
})

-- kitty specific settings
vim.opt.clipboard = ""
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
  },
}
