require "options"
require "Lazy"
require "keymaps"
require "autocommands"

vim.notify = require('notify')

local commands = require "commands"
commands.load(commands.defaults)
