require "options"
require "keymaps"
require "autocommands"
require "Lazy"

vim.notify("Starting Neovim", "info")

local commands = require "commands"
commands.load(commands.defaults)
